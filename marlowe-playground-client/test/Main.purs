module Test.Main where

import Prologue

import BridgeTests as BridgeTests
import Effect (Effect)
import Effect.Aff (launchAff_)
import Marlowe.BlocklyTests as BlocklyTests
import Marlowe.ContractTests as ContractTests
import Marlowe.DeinstantiatorTests as DeinstantiatorTests
import Marlowe.Holes.SemanticTest as HolesSemanticTest
import Marlowe.Holes.TemplateTest as HolesTemplateTest
import Marlowe.Holes.TimeoutTest as HolesTimeoutTest
import Marlowe.LintTests as LintTests
import Marlowe.ParserTests as ParserTests
import Test.Component.DateTimeLocalInputTest as DateTimeLocalInputTest
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner (runSpec)

foreign import forDeps :: Effect Unit

main :: Effect Unit
main = launchAff_ $ runSpec [ consoleReporter ] do
  BridgeTests.all
  ParserTests.all
  ContractTests.all
  BlocklyTests.all
  LintTests.all
  DeinstantiatorTests.all
  HolesSemanticTest.all
  HolesTemplateTest.all
  HolesTimeoutTest.all
  DateTimeLocalInputTest.all
