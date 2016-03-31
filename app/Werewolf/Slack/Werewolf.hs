{-|
Module      : Werewolf.Slack.Werewolf

Copyright   : (c) Henry J. Wylde, 2016
License     : BSD3
Maintainer  : public@hjwylde.com
-}

{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Werewolf.Slack.Werewolf (
    -- * Werewolf
    execute,
) where

import Control.Monad.Extra
import Control.Monad.Reader

import           Data.Aeson
import qualified Data.ByteString.Lazy.Char8 as BSLC
import           Data.Maybe
import qualified Data.Text                  as T

import Game.Werewolf

import System.Process

import Werewolf.Slack.Options
import Werewolf.Slack.Slack

execute :: (MonadIO m, MonadReader Options m) => String -> String -> m ()
execute user userCommand = whenJustM (interpret user userCommand) handle

interpret :: MonadIO m => String -> String -> m (Maybe Response)
interpret user userCommand = do
    stdout <- liftIO $ readCreateProcess (proc command arguments) ""

    return (decode (BSLC.pack stdout) :: Maybe Response)
    where
        atUser      = if take 1 user == "@" then user else '@':user
        command     = "werewolf"
        arguments   = ["--caller", atUser, "interpret", "--"] ++ words userCommand

handle :: (MonadIO m, MonadReader Options m) => Response -> m ()
handle response = do
    channelName <- asks $ ('#':) . optChannelName

    forM_ (messages response) $ \(Message mTo message) ->
        notify (fromMaybe channelName (T.unpack <$> mTo)) (T.unpack message)