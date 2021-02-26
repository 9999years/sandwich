{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
module Main where

import Common
import Data.Time.Clock
import Test.Sandwich

timingDemo :: TopSpec
timingDemo = do
  timingNode "Makes dinner" $ it "Makes dinner" $ do
    pauseSeconds 1
    timeAction "Makes pasta" $ do
      timeAction "Heats water" $ pauseSeconds 1
      timeAction "Boils noodles" $ pauseSeconds 0.8
      timeAction "Decants noodles" $ pauseSeconds 0.7

  timingNode "Cleans up" $ it "Cleans up" $ do
    pauseSeconds 1

testOptions = defaultOptions {
  optionsTestArtifactsDirectory = TestArtifactsGeneratedDirectory "test_runs" (show <$> getCurrentTime)
  }

main :: IO ()
main = runSandwichWithCommandLineArgs testOptions timingDemo