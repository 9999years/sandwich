{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE MultiWayIf #-}
-- |

module Test.Sandwich.Formatters.TerminalUI.Draw.TopBox (
  topBox
  ) where

import Brick
import qualified Brick.Widgets.List as L
import Control.Monad.Logger
import qualified Data.List as L
import Data.Maybe
import Lens.Micro
import Test.Sandwich.Formatters.TerminalUI.AttrMap
import Test.Sandwich.Formatters.TerminalUI.Keys
import Test.Sandwich.Formatters.TerminalUI.Types
import Test.Sandwich.RunTree
import Test.Sandwich.Types.RunTree


topBox app = hBox [columnPadding settingsColumn
                  , columnPadding actionsColumn
                  , columnPadding otherActionsColumn]
  where
    settingsColumn = keybindingBox [keyIndicator (L.intersperse '/' [unKChar nextKey, unKChar previousKey, '↑', '↓']) "Navigate"
                                   , keyIndicator (unKChar nextFailureKey : '/' : [unKChar previousFailureKey]) "Next/previous failure"
                                   , keyIndicator (unKChar closeNodeKey : '/' : [unKChar openNodeKey]) "Fold/unfold nodes"
                                   , keyIndicator "Meta + [0-9]" "Unfold top # nodes"
                                   , keyIndicatorHasSelected app (showKeys toggleKeys) "Toggle selected"]

    actionsColumn = keybindingBox [hBox [str "["
                                         , highlightKeyIfPredicate selectedTestRunning app (str $ showKey cancelSelectedKey)
                                         , str "/"
                                         , highlightKeyIfPredicate someTestRunning app (str $ showKey cancelAllKey)
                                         , str "] "
                                         , withAttr hotkeyMessageAttr $ str "Cancel "
                                         , highlightMessageIfPredicate selectedTestRunning app (str "selected")
                                         , str "/"
                                         , highlightMessageIfPredicate someTestRunning app (str "all")
                                         ]
                                  , hBox [str "["
                                         , highlightKeyIfPredicate selectedTestDone app (str $ showKey runSelectedKey)
                                         , str "/"
                                         , highlightKeyIfPredicate noTestsRunning app (str $ showKey runAllKey)
                                         , str "] "
                                         , withAttr hotkeyMessageAttr $ str "Run "
                                         , highlightMessageIfPredicate selectedTestDone app (str "selected")
                                         , str "/"
                                         , highlightMessageIfPredicate noTestsRunning app (str "all")
                                         ]
                                  , hBox [str "["
                                         , highlightKeyIfPredicate selectedTestDone app (str $ showKey clearSelectedKey)
                                         , str "/"
                                         , highlightKeyIfPredicate allTestsDone app (str $ showKey clearAllKey)
                                         , str "] "
                                         , withAttr hotkeyMessageAttr $ str "Clear "
                                         , highlightMessageIfPredicate selectedTestDone app (str "selected")
                                         , str "/"
                                         , highlightMessageIfPredicate allTestsDone app (str "all")
                                         ]
                                  , hBox [str "["
                                         , highlightKeyIfPredicate someTestSelected app (str $ showKey openSelectedFolderInFileExplorer)
                                         , str "/"
                                         , highlightKeyIfPredicate (const True) app (str $ showKey openTestRootKey)
                                         , str "] "
                                         , withAttr hotkeyMessageAttr $ str "Open "
                                         , highlightMessageIfPredicate someTestSelected app (str "selected")
                                         , str "/"
                                         , highlightMessageIfPredicate (const True) app (str "root")
                                         , withAttr hotkeyMessageAttr $ str " folder"
                                         ]
                                  , hBox [str "["
                                         , highlightKeyIfPredicate someTestSelected app (str $ showKey openInEditorKey)
                                         , str "/"
                                         , highlightKeyIfPredicate someTestSelected app (str $ showKey openLogsInEditorKey)
                                         , str "] "
                                         , withAttr hotkeyMessageAttr $ str "Open "
                                         , highlightMessageIfPredicate someTestSelected app (str "source")
                                         , str "/"
                                         , highlightMessageIfPredicate someTestSelected app (str "logs")
                                         , withAttr hotkeyMessageAttr $ str " in editor"
                                         ]
                                  ]

    otherActionsColumn = keybindingBox [keyIndicator' (showKey cycleVisibilityThresholdKey) (visibilityThresholdWidget app)
                                       , toggleIndicator (app ^. appShowRunTimes) (showKey toggleShowRunTimesKey) "Hide run times" "Show run times"
                                       , toggleIndicator (app ^. appShowFileLocations) (showKey toggleFileLocationsKey) "Hide file locations" "Show file locations"
                                       , toggleIndicator (app ^. appShowVisibilityThresholds) (showKey toggleVisibilityThresholdsKey) "Hide visibility thresholds" "Show visibility thresholds"
                                       , hBox [str "["
                                              , highlightIfLogLevel app LevelDebug [unKChar debugKey]
                                              , str "/"
                                              , highlightIfLogLevel app LevelInfo [unKChar infoKey]
                                              , str "/"
                                              , highlightIfLogLevel app LevelWarn [unKChar warnKey]
                                              , str "/"
                                              , highlightIfLogLevel app LevelError [unKChar errorKey]
                                              , str "] "
                                              , str "Set log level"]

                                       , keyIndicator "q" "Exit"]

visibilityThresholdWidget app = hBox $
  [withAttr hotkeyMessageAttr $ str "Change visibility threshold ("]
  <> L.intersperse (str ", ") [withAttr (if x == app ^. appVisibilityThreshold then visibilityThresholdSelectedAttr else visibilityThresholdNotSelectedAttr) $ str $ show x | x <- (app ^. appVisibilityThresholdSteps)]
  <> [(str ")")]

columnPadding = padLeft (Pad 1) . padRight (Pad 3) -- . padTop (Pad 1)

keybindingBox = vBox

highlightIfLogLevel app desiredLevel thing =
  if | app ^. appLogLevel == Just desiredLevel -> withAttr visibilityThresholdSelectedAttr $ str thing
     | otherwise -> withAttr hotkeyAttr $ str thing

highlightKeyIfPredicate p app x = case p app of
  True -> withAttr hotkeyAttr x
  False -> withAttr disabledHotkeyAttr x

highlightMessageIfPredicate p app x = case p app of
  True -> withAttr hotkeyMessageAttr x
  False -> withAttr disabledHotkeyMessageAttr x

toggleIndicator True key onMsg _ = keyIndicator key onMsg
toggleIndicator False key _ offMsg = keyIndicator key offMsg

keyIndicator key msg = keyIndicator' key (withAttr hotkeyMessageAttr $ str msg)

keyIndicator' key label = hBox [str "[", withAttr hotkeyAttr $ str key, str "] ", label]

keyIndicatorHasSelected app = keyIndicatorContextual app someTestSelected

keyIndicatorSelectedTestDone app = keyIndicatorContextual app selectedTestDone
keyIndicatorSelectedTestRunning app = keyIndicatorContextual app selectedTestRunning

keyIndicatorHasSelectedAndFolder app = keyIndicatorContextual app $ \s -> case L.listSelectedElement (s ^. appMainList) of
  Just (_, MainListElem {folderPath=(Just _)}) -> True
  _ -> False

keyIndicatorSomeTestRunning app = keyIndicatorContextual app someTestRunning
keyIndicatorNoTestsRunning app = keyIndicatorContextual app noTestsRunning
keyIndicatorAllTestsDone app = keyIndicatorContextual app allTestsDone
-- keyIndicatorSomeTestsNotDone = keyIndicatorContextual $ \s -> not $ all (isDone . runTreeStatus . runNodeCommon) (s ^. appRunTree)

keyIndicatorContextual app p key msg = case p app of
  True -> hBox [str "[", withAttr hotkeyAttr $ str key, str "] ", withAttr hotkeyMessageAttr $ str msg]
  False -> hBox [str "[", withAttr disabledHotkeyAttr $ str key, str "] ", withAttr disabledHotkeyMessageAttr $ str msg]


-- * Predicates

selectedTestRunning s = case L.listSelectedElement (s ^. appMainList) of
  Nothing -> False
  Just (_, MainListElem {..}) -> isRunning status

selectedTestDone s = case L.listSelectedElement (s ^. appMainList) of
  Nothing -> False
  Just (_, MainListElem {..}) -> isDone status

noTestsRunning s = all (not . isRunning . runTreeStatus . runNodeCommon) (s ^. appRunTree)

someTestRunning s = any (isRunning . runTreeStatus . runNodeCommon) (s ^. appRunTree)

allTestsDone s = all (isDone . runTreeStatus . runNodeCommon) (s ^. appRunTree)

someTestSelected s = isJust $ L.listSelectedElement (s ^. appMainList)
