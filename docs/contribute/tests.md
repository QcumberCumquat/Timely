# Tests

## Backend

The backend uses `ExUnit`.

To launch all the tests:
```bash
mix test
```

!!! info
    If you're using Docker, you can use `make test`

If you want test coverage:

```bash
mix coveralls.html
```

It will show the coverage and will output a `cover/excoveralls.html` file.

If you want to test a single file:

```bash
mix test test/mobilizon/actors/actors_test.exs
```

If you want to test a specific test, block or line:

```bash
mix test test/mobilizon/actors/actors_test.exs:85
```

!!! tip
    Note: The `coveralls.html` also works the same

## Front-end

### Unit tests

Not done yet.

### End-to-end tests

We use [Cypress](https://cypress.io) for End-to-end testing.

You first need to run the webserver with the `e2e` environment: `MIX_ENV=e2e mix phx.server`. The same environment parameters as the `dev` environment must be provided.
This allows to run database operations in the sandbox and not pollute your database.

Then, run `MIX_ENV=e2e mix run priv/repo/e2e.seed.exs` to have some initial data inside your instance for the tests.

When inside the `js` directory, you can do either
```bash
npx cypress run
```
to run the tests, or
```bash
npx cypress open
```
to open the interactive GUI.

!!! info
    Cypress provided [a subscription](https://www.cypress.io/oss-plan) to their recording dashboard since Mobilizon is an Open-Source project. Thanks!
