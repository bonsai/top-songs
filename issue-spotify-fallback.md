# Issue: Spotify embed preview may need a full-app fallback

## Summary
The current `spotify▶` flow uses the Spotify embed search player with `autoplay=1`, but actual playback behavior still depends on browser autoplay policy and Spotify embed support. When preview playback does not start reliably, the UI should be able to fall back to a direct Spotify app/web URL.

## Why this matters
- some environments will focus the current track but still not start audible playback
- embed behavior can vary by browser, login state, cookie state, and Spotify restrictions
- users still need a fast path to open the current song in Spotify proper

## Proposed fallback
- keep the current embedded autoplay attempt as the first behavior
- if playback cannot be confirmed or is blocked, open the regular Spotify search URL for the same track
- preserve the current track highlight and 15-second auto-advance behavior in the chart UI

## Candidate URL
`https://open.spotify.com/search/{artist%20title}`
