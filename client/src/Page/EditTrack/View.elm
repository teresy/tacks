module Page.EditTrack.View (..) where

import Html exposing (Html)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Model.Shared exposing (..)
import Page.EditTrack.Model exposing (..)
import Page.EditTrack.SideView as SideView
import View.Layout as Layout
import Game.Geo exposing (floatify)
import Game.Render.SvgUtils exposing (..)
import Game.Render.Tiles as Tiles
import Game.Render.Gates as Gates
import Game.Render.Players as Players


view : Context -> Model -> Html
view { player, dims } model =
  case ( model.track, model.editor ) of
    ( Just track, Just editor ) ->
      if canUpdateDraft player track then
        Layout.layoutWithSidebar
          "editor"
          (SideView.view track editor)
          [ renderCourse dims editor ]
      else
        Html.text "Access forbidden."

    _ ->
      Html.text "loading"


renderCourse : Dims -> Editor -> Html
renderCourse dims ({ center, course, mode } as editor) =
  let
    ( w, h ) =
      floatify (getCourseDims dims)

    cx =
      w / 2 + fst center

    cy =
      -h / 2 + snd center
  in
    Svg.svg
      [ width (toString w)
      , height (toString h)
      , class <| "mode-" ++ (modeName (realMode editor) |> fst)
      ]
      [ g
          [ transform ("scale(1,-1)" ++ (translate cx cy)) ]
          [ Tiles.lazyRenderTiles course.grid
          , Gates.renderOpenGate 0 course.start
          , g [] (List.map (Gates.renderClosedGate 0) course.gates)
          , Players.renderPlayerHull 0 0
          ]
      ]
