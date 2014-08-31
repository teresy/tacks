module Core where

ensure360 : Float -> Float
ensure360 val = 
  let rounded = round val
      excess = val - (toFloat rounded)
  in  ((rounded + 360) `mod` 360 |> toFloat) + excess

toRadians : Float -> Float
toRadians deg = radians ((90 - deg) * pi / 180)

mpsToKnts : Float -> Float
mpsToKnts mps = mps * 3600 / 1.852 / 1000

angleToWind : Float -> Float -> Float
angleToWind playerDirection windOrigin =
  let delta = playerDirection - windOrigin
  in
    if | delta > 180   -> delta - 360
       | delta <= -180 -> delta + 360
       | otherwise     -> delta

-- polynomial regression of AC72 polar
-- see http://noticeboard.americascup.com/wp-content/uploads/actv/LV13/AC72polar.130714.txt
-- and http://www.xuru.org/rt/MPR.asp
polarVelocity : Float -> Float -> Float
polarVelocity speed angle =
  let x1 = speed
      x2 = angle
      v = -2.067174789 * 10 ^ -3 * x1 ^ 3 - 1.868941044 * 10 ^ -4 * x1 ^ 2 * x2 
          - 1.03401471 * 10 ^ -4 * x1 * x2 ^ 2 - 1.86799863 * 10 ^ -5 * x2 ^ 3 
          + 7.376288713 * 10 ^ -2 * x1 ^ 2 + 3.19606466 * 10 ^ -2 * x1 * x2 
          + 2.939457021 * 10 ^ -3 * x2 ^ 2 - 8.575945237 * 10 ^ -1 * x1 
          + 9.427801906 * 10 ^ -5 * x2 + 4.342327445
  in v * 2 -- pixel speed

vmgValue : Float -> Float  -> Float
vmgValue s a = abs ((cos (toRadians a)) * (polarVelocity s a))

upwindVmg : Float -> Float
upwindVmg windSpeed =
  map (\a -> (a, vmgValue windSpeed a)) [30..60] |> sortBy snd |> last |> fst

downwindVmg : Float -> Float
downwindVmg windSpeed =
  map (\a -> (a, vmgValue windSpeed a)) [130..180] |> sortBy snd |> last |> fst

-- deals with inertia
playerVelocity : Float -> Float -> Float -> Float
playerVelocity windSpeed windAngle previousVelocity =
  let v = polarVelocity windSpeed (abs windAngle)
      delta = v - previousVelocity
  in previousVelocity + delta * 0.02

mapMaybe : (a -> b) -> Maybe a -> Maybe b
mapMaybe f maybe =
    case maybe of
      Just v  -> Just (f v)
      Nothing -> Nothing

compact : [Maybe a] -> [a]
compact maybes =
  let folder : Maybe b -> [b] -> [b]
      folder m list = case m of
                        Just j  -> j :: list
                        Nothing -> list
  in foldl folder [] maybes

average : [Float] -> Float
average items = (sum items) / (toFloat (length items))

indexedMap : (Int -> a -> b) -> [a] -> [b]
indexedMap f xs =
    zipWith f [ 0 .. length xs - 1 ] xs
