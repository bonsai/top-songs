# Bug: chart does not load on deployed/static environments

## Summary
The app is configured as a static site, but the frontend hardcodes `http://localhost:3000/api/proxy?url=` for chart fetching. As a result, the chart fails to load anywhere except a local machine that happens to run a compatible proxy on port 3000.

## Steps to reproduce
1. Open the deployed app or serve the repository as static files.
2. Click `チャートを読み込み`.
3. Observe the fetch failure and empty chart state.

## Expected
Chart data loads from kworb and renders in the table.

## Actual
The browser requests `http://localhost:3000/api/proxy?...`, which is unavailable in static deployments, so the app shows a data loading error.

## Root cause
- `render.yaml` deploys the project as `env: static`
- `index.html` depends on a local proxy at `http://localhost:3000/api/proxy`
- the repository does not provide that proxy runtime in deployment

## Proposed fix
- serve the app with a small Node server
- expose a relative `/api/proxy?url=` endpoint
- proxy only the kworb domain
- update the frontend to use the relative endpoint
