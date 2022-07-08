{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DefaultSignatures          #-}
{-# LANGUAGE DeriveAnyClass             #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE DerivingVia                #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE NamedFieldPuns             #-}
{-# LANGUAGE NoImplicitPrelude          #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE RankNTypes                 #-}
{-# LANGUAGE RecordWildCards            #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE UndecidableInstances       #-}

-- Big hammer, but helps
{-# OPTIONS_GHC -fno-specialise #-}
{-# OPTIONS_GHC -Wno-name-shadowing #-}

{-# OPTIONS_GHC -fno-ignore-interface-pragmas #-}
{-# OPTIONS_GHC -fno-warn-orphans       #-}
{-# OPTIONS_GHC -Wno-simplifiable-class-constraints #-}
{-# OPTIONS_GHC -fno-omit-interface-pragmas #-}


{-| = Marlowe: financial contracts domain specific language for blockchain

Here we present a reference implementation of Marlowe, domain-specific language targeted at
the execution of financial contracts in the style of Peyton Jones et al
on Cardano.

== Semantics

Semantics is based on <https://github.com/input-output-hk/marlowe/blob/stable/src/Semantics.hs>

Marlowe Contract execution is a chain of transactions,
where remaining contract and its state is passed through /Datum/,
and actions (i.e. /Choices/) are passed as
/Redeemer Script/

/Validation Script/ is always the same Marlowe interpreter implementation, available below.
-}

module Language.Marlowe.Core.V1.Semantics where

import Control.Applicative ((<*>), (<|>))
import qualified Data.Aeson as JSON
import Data.Aeson.Types hiding (Error, Value)
import qualified Data.Foldable as F
import Data.Scientific (Scientific)
import Data.Text (pack)
import Deriving.Aeson
import Language.Marlowe.Core.V1.Semantics.Types (AccountId, Accounts, Action (..), Case (..), Contract (..),
                                                 Environment (..), Input (..), InputContent (..), IntervalError (..),
                                                 IntervalResult (..), Money, Observation (..), Party, Payee (..),
                                                 State (..), TimeInterval, Token (..), Value (..), ValueId, emptyState,
                                                 getAction, getInputContent, inBounds)
import Language.Marlowe.ParserUtil (getInteger, withInteger)
import Language.Marlowe.Pretty (Pretty (..))
import Ledger (POSIXTime (..), ValidatorHash)
import Ledger.Value (CurrencySymbol (..))
import qualified Ledger.Value as Val
import PlutusTx (makeIsDataIndexed)
import qualified PlutusTx.AssocMap as Map
import qualified PlutusTx.Builtins as Builtins
import PlutusTx.Lift (makeLift)
import PlutusTx.Prelude hiding (encodeUtf8, mapM, (<$>), (<*>), (<>))
import Prelude (mapM, (<$>))
import qualified Prelude as Haskell
import Text.PrettyPrint.Leijen (comma, hang, lbrace, line, rbrace, space, text, (<>))

{- HLINT ignore "Avoid restricted function" -}

{- Functions that used in Plutus Core must be inlineable,
   so their code is available for PlutusTx compiler -}
{-# INLINABLE fixInterval #-}
{-# INLINABLE evalValue #-}
{-# INLINABLE evalObservation #-}
{-# INLINABLE refundOne #-}
{-# INLINABLE moneyInAccount #-}
{-# INLINABLE updateMoneyInAccount #-}
{-# INLINABLE addMoneyToAccount #-}
{-# INLINABLE giveMoney #-}
{-# INLINABLE reduceContractStep #-}
{-# INLINABLE reduceContractUntilQuiescent #-}
{-# INLINABLE applyAction #-}
{-# INLINABLE getContinuation #-}
{-# INLINABLE applyCases #-}
{-# INLINABLE applyInput #-}
{-# INLINABLE convertReduceWarnings #-}
{-# INLINABLE applyAllInputs #-}
{-# INLINABLE isClose #-}
{-# INLINABLE computeTransaction #-}
{-# INLINABLE contractLifespanUpperBound #-}
{-# INLINABLE totalBalance #-}

{-| Payment occurs during 'Pay' contract evaluation, and
    when positive balances are payed out on contract closure.
-}
data Payment = Payment AccountId Payee Money
  deriving stock (Haskell.Show)


-- | Effect of 'reduceContractStep' computation
data ReduceEffect = ReduceWithPayment Payment
                  | ReduceNoPayment
  deriving stock (Haskell.Show)


-- | Warning during 'reduceContractStep'
data ReduceWarning t = ReduceNoWarning
                     | ReduceNonPositivePay AccountId Payee t Integer
                     | ReducePartialPay AccountId Payee t Integer Integer
--                                        ^ src    ^ dest    ^ paid ^ expected
                     | ReduceShadowing ValueId Integer Integer
--                                       oldVal ^  newVal ^
                     | ReduceAssertionFailed
  deriving stock (Haskell.Show)


-- | Result of 'reduceContractStep'
data ReduceStepResult t = Reduced (ReduceWarning t) ReduceEffect (State t) (Contract t)
                        | NotReduced
                        | AmbiguousTimeIntervalReductionError
  deriving stock (Haskell.Show)


-- | Result of 'reduceContractUntilQuiescent'
data ReduceResult t = ContractQuiescent Bool [ReduceWarning t] [Payment] (State t) (Contract t)
                    | RRAmbiguousTimeIntervalError
  deriving stock (Haskell.Show)


-- | Warning of 'applyCases'
data ApplyWarning t = ApplyNoWarning
                    | ApplyNonPositiveDeposit Party AccountId t Integer
  deriving stock (Haskell.Show)


-- | Result of 'applyCases'
data ApplyResult t = Applied (ApplyWarning t) (State t) (Contract t)
                   | ApplyNoMatchError
                   | ApplyHashMismatch
  deriving stock (Haskell.Show)


-- | Result of 'applyAllInputs'
data ApplyAllResult t = ApplyAllSuccess Bool [TransactionWarning t] [Payment] (State t) (Contract t)
                      | ApplyAllNoMatchError
                      | ApplyAllAmbiguousTimeIntervalError
                      | ApplyAllHashMismatch
  deriving stock (Haskell.Show)


-- | Warnings during transaction computation
data TransactionWarning t = TransactionNonPositiveDeposit Party AccountId t Integer
                          | TransactionNonPositivePay AccountId Payee t Integer
                          | TransactionPartialPay AccountId Payee t Integer Integer
--                                                   ^ src    ^ dest     ^ paid   ^ expected
                          | TransactionShadowing ValueId Integer Integer
--                                                   oldVal ^  newVal ^
                          | TransactionAssertionFailed
  deriving stock (Haskell.Show, Generic, Haskell.Eq)
  deriving anyclass (Pretty)


-- | Transaction error
data TransactionError = TEAmbiguousTimeIntervalError
                      | TEApplyNoMatchError
                      | TEIntervalError IntervalError
                      | TEUselessTransaction
                      | TEHashMismatch
  deriving stock (Haskell.Show, Generic, Haskell.Eq)
  deriving anyclass (ToJSON, FromJSON)


{-| Marlowe transaction input.
-}
data TransactionInput t = TransactionInput
    { txInterval :: TimeInterval
    , txInputs   :: [Input t] }
  deriving stock (Haskell.Show, Haskell.Eq)

instance Pretty t => Pretty (TransactionInput t) where
    prettyFragment tInp = text "TransactionInput" <> space <> lbrace <> line <> txIntLine <> line <> txInpLine
        where
            txIntLine = hang 2 $ text "txInterval = " <> prettyFragment (txInterval tInp) <> comma
            txInpLine = hang 2 $ text "txInputs = " <> prettyFragment (txInputs tInp) <> rbrace


{-| Marlowe transaction output.
-}
data TransactionOutput t =
    TransactionOutput
        { txOutWarnings :: [TransactionWarning t]
        , txOutPayments :: [Payment]
        , txOutState    :: State t
        , txOutContract :: Contract t }
    | Error TransactionError
  deriving stock (Haskell.Show)


{-|
    This data type is a content of a contract's /Datum/
-}
data MarloweData = MarloweData {
        marloweState    :: State Token,
        marloweContract :: Contract Token
    } deriving stock (Haskell.Show, Haskell.Eq, Generic)
      deriving anyclass (ToJSON, FromJSON)


data MarloweParams = MarloweParams {
        rolePayoutValidatorHash :: ValidatorHash,
        rolesCurrency           :: CurrencySymbol
    }
  deriving stock (Haskell.Show,Generic,Haskell.Eq,Haskell.Ord)
  deriving anyclass (FromJSON,ToJSON)


{- Checks 'interval' and trim it if necessary. -}
fixInterval :: TimeInterval -> State Token -> IntervalResult Token
fixInterval interval state =
    case interval of
        (low, high)
          | high < low -> IntervalError (InvalidInterval interval)
          | otherwise -> let
            curMinTime = minTime state
            -- newLow is both new "low" and new "minTime" (the lower bound for slotNum)
            newLow = max low curMinTime
            -- We know high is greater or equal than newLow (prove)
            curInterval = (newLow, high)
            env = Environment { timeInterval = curInterval }
            newState = state { minTime = newLow }
            in if high < curMinTime then IntervalError (IntervalInPastError curMinTime interval)
            else IntervalTrimmed env newState


{-|
  Evaluates @Value@ given current @State@ and @Environment@
-}
evalValue :: Environment -> State Token -> Value (Observation Token) Token -> Integer
evalValue env state value = let
    eval = evalValue env state
    in case value of
        AvailableMoney accId token -> moneyInAccount accId token (accounts state)
        Constant integer     -> integer
        NegValue val         -> negate (eval val)
        AddValue lhs rhs     -> eval lhs + eval rhs
        SubValue lhs rhs     -> eval lhs - eval rhs
        MulValue lhs rhs     -> eval lhs * eval rhs
        DivValue lhs rhs     -> let n = eval lhs
                                in if n == 0 then 0 else let
                                    d = eval rhs
                                in if d == 0 then 0 else let
                                    (q, r) = n `quotRem` d
                                    ar = abs r * 2
                                    ad = abs d
                                in if ar < ad then q -- reminder < 1/2
                                   else if ar > ad then q + signum n * signum d -- reminder > 1/2
                                   else let -- reminder == 1/2
                                qIsEven = q `Builtins.remainderInteger` 2 == 0
                                in if qIsEven then q else q + signum n * signum d
        ChoiceValue choiceId ->
            case Map.lookup choiceId (choices state) of
                Just x  -> x
                Nothing -> 0
        TimeIntervalStart    -> getPOSIXTime (fst (timeInterval env))
        TimeIntervalEnd      -> getPOSIXTime (snd (timeInterval env))
        UseValue valId       ->
            case Map.lookup valId (boundValues state) of
                Just x  -> x
                Nothing -> 0
        Cond cond thn els    -> if evalObservation env state cond then eval thn else eval els
  where
    abs :: Integer -> Integer
    abs a = if a >= 0 then a else negate a

    signum :: Integer -> Integer
    signum x
      | x > 0 = 1
      | x == 0 = 0
      | otherwise = -1


-- | Evaluate 'Observation' to 'Bool'.
evalObservation :: Environment -> State Token -> Observation Token -> Bool
evalObservation env state obs = let
    evalObs = evalObservation env state
    evalVal = evalValue env state
    in case obs of
        AndObs lhs rhs          -> evalObs lhs && evalObs rhs
        OrObs lhs rhs           -> evalObs lhs || evalObs rhs
        NotObs subObs           -> not (evalObs subObs)
        ChoseSomething choiceId -> choiceId `Map.member` choices state
        ValueGE lhs rhs         -> evalVal lhs >= evalVal rhs
        ValueGT lhs rhs         -> evalVal lhs > evalVal rhs
        ValueLT lhs rhs         -> evalVal lhs < evalVal rhs
        ValueLE lhs rhs         -> evalVal lhs <= evalVal rhs
        ValueEQ lhs rhs         -> evalVal lhs == evalVal rhs
        TrueObs                 -> True
        FalseObs                -> False


-- | Pick the first account with money in it
refundOne :: Accounts Token -> Maybe ((Party, Money), Accounts Token)
refundOne accounts = case Map.toList accounts of
    [] -> Nothing
    ((accId, Token cur tok), balance) : rest ->
        if balance > 0
        then Just ((accId, Val.singleton cur tok balance), Map.fromList rest)
        else refundOne (Map.fromList rest)


-- | Obtains the amount of money available an account
moneyInAccount :: AccountId -> Token -> Accounts Token -> Integer
moneyInAccount accId token accounts = case Map.lookup (accId, token) accounts of
    Just x  -> x
    Nothing -> 0


-- | Sets the amount of money available in an account
updateMoneyInAccount :: AccountId -> Token -> Integer -> Accounts Token -> Accounts Token
updateMoneyInAccount accId token amount =
    if amount <= 0 then Map.delete (accId, token) else Map.insert (accId, token) amount


-- Add the given amount of money to an accoun (only if it is positive)
-- Return the updated Map
addMoneyToAccount :: AccountId -> Token -> Integer -> Accounts Token -> Accounts Token
addMoneyToAccount accId token amount accounts = let
    balance = moneyInAccount accId token accounts
    newBalance = balance + amount
    in if amount <= 0 then accounts
    else updateMoneyInAccount accId token newBalance accounts


{-| Gives the given amount of money to the given payee.
    Returns the appropriate effect and updated accounts
-}
giveMoney :: AccountId -> Payee -> Token -> Integer -> Accounts Token -> (ReduceEffect, Accounts Token)
giveMoney accountId payee (Token cur tok) amount accounts = let
    newAccounts = case payee of
        Party _       -> accounts
        Account accId -> addMoneyToAccount accId (Token cur tok) amount accounts
    in (ReduceWithPayment (Payment accountId payee (Val.singleton cur tok amount)), newAccounts)


-- | Carry a step of the contract with no inputs
reduceContractStep :: Environment -> State Token -> Contract Token -> ReduceStepResult Token
reduceContractStep env state contract = case contract of

    Close -> case refundOne (accounts state) of
        Just ((party, money), newAccounts) -> let
            newState = state { accounts = newAccounts }
            in Reduced ReduceNoWarning (ReduceWithPayment (Payment party (Party party) money)) newState Close
        Nothing -> NotReduced

    Pay accId payee tok val cont -> let
        amountToPay = evalValue env state val
        in  if amountToPay <= 0
            then let
                warning = ReduceNonPositivePay accId payee tok amountToPay
                in Reduced warning ReduceNoPayment state cont
            else let
                balance    = moneyInAccount accId tok (accounts state)
                paidAmount = min balance amountToPay
                newBalance = balance - paidAmount
                newAccs = updateMoneyInAccount accId tok newBalance (accounts state)
                warning = if paidAmount < amountToPay
                          then ReducePartialPay accId payee tok paidAmount amountToPay
                          else ReduceNoWarning
                (payment, finalAccs) = giveMoney accId payee tok paidAmount newAccs
                newState = state { accounts = finalAccs }
                in Reduced warning payment newState cont

    If obs cont1 cont2 -> let
        cont = if evalObservation env state obs then cont1 else cont2
        in Reduced ReduceNoWarning ReduceNoPayment state cont

    When _ timeout cont -> let
        startSlot = fst (timeInterval env)
        endSlot   = snd (timeInterval env)
        -- if timeout in future – do not reduce
        in if endSlot < timeout then NotReduced
        -- if timeout in the past – reduce to timeout continuation
        else if timeout <= startSlot then Reduced ReduceNoWarning ReduceNoPayment state cont
        -- if timeout in the time range – issue an ambiguity error
        else AmbiguousTimeIntervalReductionError

    Let valId val cont -> let
        evaluatedValue = evalValue env state val
        boundVals = boundValues state
        newState = state { boundValues = Map.insert valId evaluatedValue boundVals }
        warn = case Map.lookup valId boundVals of
              Just oldVal -> ReduceShadowing valId oldVal evaluatedValue
              Nothing     -> ReduceNoWarning
        in Reduced warn ReduceNoPayment newState cont

    Assert obs cont -> let
        warning = if evalObservation env state obs
                  then ReduceNoWarning
                  else ReduceAssertionFailed
        in Reduced warning ReduceNoPayment state cont

-- | Reduce a contract until it cannot be reduced more
reduceContractUntilQuiescent :: Environment -> State Token -> Contract Token -> ReduceResult Token
reduceContractUntilQuiescent env state contract = let
    reductionLoop
      :: Bool -> Environment -> State Token -> Contract Token -> [ReduceWarning Token] -> [Payment] -> ReduceResult Token
    reductionLoop reduced env state contract warnings payments =
        case reduceContractStep env state contract of
            Reduced warning effect newState cont -> let
                newWarnings = case warning of
                                ReduceNoWarning -> warnings
                                _               -> warning : warnings
                newPayments  = case effect of
                    ReduceWithPayment payment -> payment : payments
                    ReduceNoPayment           -> payments
                in reductionLoop True env newState cont newWarnings newPayments
            AmbiguousTimeIntervalReductionError -> RRAmbiguousTimeIntervalError
            -- this is the last invocation of reductionLoop, so we can reverse lists
            NotReduced -> ContractQuiescent reduced (reverse warnings) (reverse payments) state contract

    in reductionLoop False env state contract [] []

data ApplyAction = AppliedAction (ApplyWarning Token) (State Token)
                 | NotAppliedAction
  deriving stock (Haskell.Show)

-- | Try to apply a single input content to a single action
applyAction :: Environment -> State Token -> InputContent Token -> Action Token -> ApplyAction
applyAction env state (IDeposit accId1 party1 tok1 amount) (Deposit accId2 party2 tok2 val) =
    if accId1 == accId2 && party1 == party2 && tok1 == tok2 && amount == evalValue env state val
    then let warning = if amount > 0 then ApplyNoWarning
                       else ApplyNonPositiveDeposit party2 accId2 tok2 amount
             newAccounts = addMoneyToAccount accId1 tok1 amount (accounts state)
             newState = state { accounts = newAccounts }
         in AppliedAction warning newState
    else NotAppliedAction
applyAction _ state (IChoice choId1 choice) (Choice choId2 bounds) =
    if choId1 == choId2 && inBounds choice bounds
    then let newState = state { choices = Map.insert choId1 choice (choices state) }
         in AppliedAction ApplyNoWarning newState
    else NotAppliedAction
applyAction env state INotify (Notify obs)
    | evalObservation env state obs = AppliedAction ApplyNoWarning state
applyAction _ _ _ _ = NotAppliedAction

-- | Try to get a continuation from a pair of Input and Case
getContinuation :: Input Token -> Case (Contract Token) Token -> Maybe (Contract Token)
getContinuation (NormalInput _) (Case _ continuation) = Just continuation
getContinuation (MerkleizedInput _ inputContinuationHash continuation) (MerkleizedCase _ continuationHash) =
    if inputContinuationHash == continuationHash
    then Just continuation
    else Nothing
getContinuation _ _ = Nothing

applyCases :: Environment -> State Token -> Input Token -> [Case (Contract Token) Token] -> ApplyResult Token
applyCases env state input (headCase : tailCase) =
    let inputContent = getInputContent input :: InputContent Token
        action = getAction headCase :: Action Token
        maybeContinuation = getContinuation input headCase :: Maybe (Contract Token)
    in case applyAction env state inputContent action of
         AppliedAction warning newState ->
           case maybeContinuation of
             Just continuation -> Applied warning newState continuation
             Nothing           -> ApplyHashMismatch
         NotAppliedAction -> applyCases env state input tailCase
applyCases _ _ _ [] = ApplyNoMatchError

-- | Apply a single @Input@ to a current contract
applyInput :: Environment -> State Token -> Input Token -> Contract Token -> ApplyResult Token
applyInput env state input (When cases _ _) = applyCases env state input cases
applyInput _ _ _ _                          = ApplyNoMatchError

-- | Propagate 'ReduceWarning' to 'TransactionWarning'
convertReduceWarnings :: [ReduceWarning Token] -> [TransactionWarning Token]
convertReduceWarnings = foldr (\warn acc -> case warn of
    ReduceNoWarning -> acc
    ReduceNonPositivePay accId payee tok amount ->
        TransactionNonPositivePay accId payee tok amount : acc
    ReducePartialPay accId payee tok paid expected ->
        TransactionPartialPay accId payee tok paid expected : acc
    ReduceShadowing valId oldVal newVal ->
        TransactionShadowing valId oldVal newVal : acc
    ReduceAssertionFailed ->
        TransactionAssertionFailed : acc
    ) []

-- | Apply a list of Inputs to the contract
applyAllInputs :: Environment -> State Token -> Contract Token -> [Input Token] -> ApplyAllResult Token
applyAllInputs env state contract inputs = let
    applyAllLoop
        :: Bool
        -> Environment
        -> State Token
        -> Contract Token
        -> [Input Token]
        -> [TransactionWarning Token]
        -> [Payment]
        -> ApplyAllResult Token
    applyAllLoop contractChanged env state contract inputs warnings payments =
        case reduceContractUntilQuiescent env state contract of
            RRAmbiguousTimeIntervalError -> ApplyAllAmbiguousTimeIntervalError
            ContractQuiescent reduced reduceWarns pays curState cont -> case inputs of
                [] -> ApplyAllSuccess
                    (contractChanged || reduced)
                    (warnings ++ convertReduceWarnings reduceWarns)
                    (payments ++ pays)
                    curState
                    cont
                (input : rest) -> case applyInput env curState input cont of
                    Applied applyWarn newState cont ->
                        applyAllLoop
                            True
                            env
                            newState
                            cont
                            rest
                            (warnings
                                ++ convertReduceWarnings reduceWarns
                                ++ convertApplyWarning applyWarn)
                            (payments ++ pays)
                    ApplyNoMatchError -> ApplyAllNoMatchError
                    ApplyHashMismatch -> ApplyAllHashMismatch
    in applyAllLoop False env state contract inputs [] []
  where
    convertApplyWarning :: ApplyWarning Token -> [TransactionWarning Token]
    convertApplyWarning warn =
        case warn of
            ApplyNoWarning -> []
            ApplyNonPositiveDeposit party accId tok amount ->
                [TransactionNonPositiveDeposit party accId tok amount]

isClose :: Contract Token -> Bool
isClose Close = True
isClose _     = False

-- | Try to compute outputs of a transaction given its inputs, a contract, and it's @State@
computeTransaction :: TransactionInput Token -> State Token -> Contract Token -> TransactionOutput Token
computeTransaction tx state contract = let
    inputs = txInputs tx
    in case fixInterval (txInterval tx) state of
        IntervalTrimmed env fixState -> case applyAllInputs env fixState contract inputs of
            ApplyAllSuccess reduced warnings payments newState cont ->
                    if not reduced && (not (isClose contract) || (Map.null $ accounts state))
                    then Error TEUselessTransaction
                    else TransactionOutput { txOutWarnings = warnings
                                           , txOutPayments = payments
                                           , txOutState = newState
                                           , txOutContract = cont }
            ApplyAllNoMatchError -> Error TEApplyNoMatchError
            ApplyAllAmbiguousTimeIntervalError -> Error TEAmbiguousTimeIntervalError
            ApplyAllHashMismatch -> Error TEHashMismatch
        IntervalError error -> Error (TEIntervalError error)

playTraceAux :: TransactionOutput Token -> [TransactionInput Token] -> TransactionOutput Token
playTraceAux res [] = res
playTraceAux TransactionOutput
                { txOutWarnings = warnings
                , txOutPayments = payments
                , txOutState = state
                , txOutContract = cont } (h:t) =
    let transRes = computeTransaction h state cont
     in case transRes of
          TransactionOutput{..} ->
              playTraceAux TransactionOutput
                              { txOutPayments = payments ++ txOutPayments
                              , txOutWarnings = warnings ++ txOutWarnings
                              , txOutState
                              , txOutContract
                              } t
          Error _ -> transRes
playTraceAux err@(Error _) _ = err

playTrace :: POSIXTime -> Contract Token -> [TransactionInput Token] -> TransactionOutput Token
playTrace minTime c = playTraceAux TransactionOutput
                                 { txOutWarnings = []
                                 , txOutPayments = []
                                 , txOutState = emptyState minTime
                                 , txOutContract = c
                                 }


-- | Calculates an upper bound for the maximum lifespan of a contract (assuming is not merkleized)
contractLifespanUpperBound :: Contract Token -> POSIXTime
contractLifespanUpperBound contract = case contract of
    Close -> 0
    Pay _ _ _ _ cont -> contractLifespanUpperBound cont
    If _ contract1 contract2 ->
        max (contractLifespanUpperBound contract1) (contractLifespanUpperBound contract2)
    When cases timeout subContract -> let
        contractsLifespans = [contractLifespanUpperBound c | Case _ c <- cases]
        in Haskell.maximum (timeout : contractLifespanUpperBound subContract : contractsLifespans)
    Let _ _ cont -> contractLifespanUpperBound cont
    Assert _ cont -> contractLifespanUpperBound cont


totalBalance :: Accounts Token -> Money
totalBalance accounts = foldMap
    (\((_, Token cur tok), balance) -> Val.singleton cur tok balance)
    (Map.toList accounts)


{-|
    Check that all accounts have positive balance.
 -}
validateBalances :: State Token -> Bool
validateBalances State{..} = all (\(_, balance) -> balance > 0) (Map.toList accounts)


-- Typeclass instances

instance FromJSON t => FromJSON (TransactionInput t) where
  parseJSON (Object v) =
        TransactionInput <$> (parseTimeInterval =<< (v .: "tx_interval"))
                         <*> ((v .: "tx_inputs") >>=
                   withArray "Transaction input list" (\cl ->
                     mapM parseJSON (F.toList cl)
                                                      ))
    where parseTimeInterval = withObject "TimeInterval" (\v ->
            do from <- POSIXTime <$> (withInteger =<< (v .: "from"))
               to <- POSIXTime <$> (withInteger =<< (v .: "to"))
               return (from, to)
                                                      )
  parseJSON _ = Haskell.fail "TransactionInput must be an object"

instance ToJSON t => ToJSON (TransactionInput t) where
  toJSON (TransactionInput (POSIXTime from, POSIXTime to) txInps) = object
      [ "tx_interval" .= timeIntervalJSON
      , "tx_inputs" .= toJSONList (map toJSON txInps)
      ]
    where timeIntervalJSON = object [ "from" .= from
                                    , "to" .= to
                                    ]

instance FromJSON t => FromJSON (TransactionWarning t) where
  parseJSON (String "assertion_failed") = return TransactionAssertionFailed
  parseJSON (Object v) =
        (TransactionNonPositiveDeposit <$> (v .: "party")
                                       <*> (v .: "in_account")
                                       <*> (v .: "of_token")
                                       <*> (v .: "asked_to_deposit"))
    <|> (do maybeButOnlyPaid <- v .:? "but_only_paid"
            case maybeButOnlyPaid :: Maybe Scientific of
              Nothing -> TransactionNonPositivePay <$> (v .: "account")
                                                   <*> (v .: "to_payee")
                                                   <*> (v .: "of_token")
                                                   <*> (v .: "asked_to_pay")
              Just butOnlyPaid -> TransactionPartialPay <$> (v .: "account")
                                                        <*> (v .: "to_payee")
                                                        <*> (v .: "of_token")
                                                        <*> getInteger butOnlyPaid
                                                        <*> (v .: "asked_to_pay"))
    <|> (TransactionShadowing <$> (v .: "value_id")
                              <*> (v .: "had_value")
                              <*> (v .: "is_now_assigned"))
  parseJSON _ = Haskell.fail "Contract must be either an object or a the string \"close\""

instance ToJSON t => ToJSON (TransactionWarning t) where
  toJSON (TransactionNonPositiveDeposit party accId tok amount) = object
      [ "party" .= party
      , "asked_to_deposit" .= amount
      , "of_token" .= tok
      , "in_account" .= accId
      ]
  toJSON (TransactionNonPositivePay accId payee tok amount) = object
      [ "account" .= accId
      , "asked_to_pay" .= amount
      , "of_token" .= tok
      , "to_payee" .= payee
      ]
  toJSON (TransactionPartialPay accId payee tok paid expected) = object
      [ "account" .= accId
      , "asked_to_pay" .= expected
      , "of_token" .= tok
      , "to_payee" .= payee
      , "but_only_paid" .= paid
      ]
  toJSON (TransactionShadowing valId oldVal newVal) = object
      [ "value_id" .= valId
      , "had_value" .= oldVal
      , "is_now_assigned" .= newVal
      ]
  toJSON TransactionAssertionFailed = JSON.String $ pack "assertion_failed"


instance Eq Payment where
    {-# INLINABLE (==) #-}
    Payment a1 p1 m1 == Payment a2 p2 m2 = a1 == a2 && p1 == p2 && m1 == m2


instance Eq t => Eq (ReduceWarning t) where
    {-# INLINABLE (==) #-}
    ReduceNoWarning == ReduceNoWarning = True
    (ReduceNonPositivePay acc1 p1 tn1 a1) == (ReduceNonPositivePay acc2 p2 tn2 a2) =
        acc1 == acc2 && p1 == p2 && tn1 == tn2 && a1 == a2
    (ReducePartialPay acc1 p1 tn1 a1 e1) == (ReducePartialPay acc2 p2 tn2 a2 e2) =
        acc1 == acc2 && p1 == p2 && tn1 == tn2 && a1 == a2 && e1 == e2
    (ReduceShadowing v1 old1 new1) == (ReduceShadowing v2 old2 new2) =
        v1 == v2 && old1 == old2 && new1 == new2
    _ == _ = False


instance Eq ReduceEffect where
    {-# INLINABLE (==) #-}
    ReduceNoPayment == ReduceNoPayment           = True
    ReduceWithPayment p1 == ReduceWithPayment p2 = p1 == p2
    _ == _                                       = False



-- Lifting data types to Plutus Core
makeLift ''IntervalError
makeLift ''IntervalResult
makeLift ''Payment
makeLift ''ReduceEffect
makeLift ''ReduceWarning
makeLift ''ReduceStepResult
makeLift ''ReduceResult
makeLift ''ApplyWarning
makeLift ''ApplyResult
makeLift ''ApplyAllResult
makeLift ''TransactionWarning
makeLift ''TransactionError
makeLift ''TransactionOutput
makeLift ''MarloweData
makeIsDataIndexed ''MarloweData [('MarloweData,0)]
makeLift ''MarloweParams
