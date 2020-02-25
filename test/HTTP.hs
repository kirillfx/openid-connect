{-|

Copyright:

  This file is part of the package openid-connect.  It is subject to
  the license terms in the LICENSE file found in the top-level
  directory of this distribution and at:

    https://code.devalot.com/sthenauth/openid-connect

  No part of this package, including this file, may be copied,
  modified, propagated, or distributed except according to the terms
  contained in the LICENSE file.

License: BSD-2-Clause

-}
module HTTP
  ( FakeHTTPS(..)
  , defaultFakeHTTPS
  , mkHTTPS
  , runHTTPS
  ) where

--------------------------------------------------------------------------------
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Monad.State.Strict
import qualified Data.ByteString.Lazy.Char8 as LChar8
import qualified Network.HTTP.Client.Internal as HTTP
import qualified Network.HTTP.Types as HTTP
import qualified Network.HTTP.Types.Header as HTTP

--------------------------------------------------------------------------------
data FakeHTTPS = FakeHTTPS
  { fakeStatus   :: HTTP.Status
  , fakeVersion  :: HTTP.HttpVersion
  , fakeHeaders  :: HTTP.ResponseHeaders
  , fakeDataFile :: FilePath
  }

--------------------------------------------------------------------------------
defaultFakeHTTPS :: FilePath -> FakeHTTPS
defaultFakeHTTPS file =
  FakeHTTPS
    { fakeStatus = HTTP.status200
    , fakeVersion = HTTP.http20
    , fakeHeaders = headers
    , fakeDataFile = file
    }
  where
    headers :: HTTP.ResponseHeaders
    headers =
      [ (HTTP.hDate,         "Thu, 20 Feb 2020 19:40:21 GMT")
      , (HTTP.hExpires,      "Thu, 20 Feb 2020 21:40:21 GMT")
      , (HTTP.hCacheControl, "public, max-age=3600")
      , (HTTP.hContentType,  "application/json")
      ]

--------------------------------------------------------------------------------
mkHTTPS
  :: MonadIO m
  => FakeHTTPS
  -> (HTTP.Request -> StateT HTTP.Request m (HTTP.Response LChar8.ByteString))
mkHTTPS FakeHTTPS{..} request = do
  put request

  HTTP.Response
    <$> pure fakeStatus
    <*> pure fakeVersion
    <*> pure fakeHeaders
    <*> liftIO (LChar8.readFile fakeDataFile)
    <*> pure mempty
    <*> pure (HTTP.ResponseClose (pure ()))

--------------------------------------------------------------------------------
runHTTPS
  :: StateT HTTP.Request m a
  -> m (a, HTTP.Request)
runHTTPS = (`runStateT` HTTP.defaultRequest)