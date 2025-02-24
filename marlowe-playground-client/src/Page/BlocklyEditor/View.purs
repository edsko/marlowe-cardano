module Page.BlocklyEditor.View where

import Prologue hiding (div)

import Blockly.Internal (block, blockType, style, x, xml, y)
import Component.Blockly.State as Blockly
import Component.BottomPanel.Types (Action(..)) as BottomPanel
import Component.BottomPanel.View (render) as BottomPanel
import Data.Array as Array
import Data.Bifunctor (bimap)
import Data.Lens ((^.))
import Data.Maybe (isJust)
import Effect.Aff.Class (class MonadAff)
import Halogen (ComponentHTML)
import Halogen.Classes
  ( flex
  , flexCol
  , fullHeight
  , group
  , maxH70p
  , minH0
  , overflowHidden
  , paddingX
  )
import Halogen.Css (classNames)
import Halogen.Extra (renderSubmodule)
import Halogen.HTML (HTML, button, div, section, slot, text)
import Halogen.HTML.Events (onClick)
import Halogen.HTML.Properties (classes, enabled, id)
import Language.Marlowe.Extended.V1.Metadata (MetaData)
import MainFrame.Types (ChildSlots, _blocklySlot)
import Marlowe.Blockly as MB
import Page.BlocklyEditor.BottomPanel (panelContents)
import Page.BlocklyEditor.Types
  ( Action(..)
  , BottomPanelView(..)
  , State
  , _bottomPanelState
  , _hasHoles
  , _marloweCode
  , _warnings
  )

render
  :: forall m
   . MonadAff m
  => MetaData
  -> State
  -> ComponentHTML Action ChildSlots m
render metadata state =
  div [ classes [ flex, flexCol, fullHeight ] ]
    [ section
        [ classes [ paddingX, minH0, overflowHidden, fullHeight ]
        ]
        [ slot _blocklySlot unit
            ( Blockly.blocklyComponent
                MB.rootBlockName
                MB.blockDefinitions
                MB.toolbox
            )
            { tzOffset: state.tzOffset }
            HandleBlocklyMessage
        , workspaceBlocks
        ]
    , section [ classes [ paddingX, maxH70p ] ]
        [ renderSubmodule
            _bottomPanelState
            BottomPanelAction
            (BottomPanel.render panelTitles wrapBottomPanelContents)
            state
        ]
    ]
  where
  panelTitles =
    [ { title: "Metadata", view: MetadataView, classes: [] }
    , { title: "Static Analysis", view: StaticAnalysisView, classes: [] }
    , { title: warningsTitle, view: BlocklyWarningsView, classes: [] }
    ]

  withCount str arry = str <>
    if Array.null arry then "" else " (" <> show (Array.length arry) <> ")"

  warningsTitle = withCount "Warnings" $ state ^. _warnings

  -- TODO: improve this wrapper helper
  actionWrapper = BottomPanel.PanelAction

  wrapBottomPanelContents panelView = bimap (map actionWrapper) actionWrapper $
    panelContents state metadata panelView

workspaceBlocks :: forall a b. HTML a b
workspaceBlocks =
  xml [ id "workspaceBlocks", style "display:none" ]
    [ block
        [ blockType (show MB.BaseContractType)
        , x "13"
        , y "187"
        , id MB.rootBlockName
        ]
        []
    ]

otherActions
  :: forall p
   . State
  -> HTML p Action
otherActions state =
  div [ classes [ group ] ]
    [ button
        [ onClick $ const ViewAsMarlowe
        , enabled hasCode
        , classNames [ "btn" ]
        ]
        [ text "View as Marlowe" ]
    , button
        [ onClick $ const SendToSimulator
        , enabled (hasCode && not hasHoles)
        , classNames [ "btn" ]
        ]
        [ text "Send To Simulator" ]
    ]
  where
  hasCode = isJust $ state ^. _marloweCode

  hasHoles = state ^. _hasHoles
