# StrongstartRelease

A private ruby gem that adds the following rake tasks to the development environment of a Strong Start web application - SiTE SOURCE or GRFS:

| Task                                  | Description                                                                                                           |
|---------------------------------------|-----------------------------------------------------------------------------------------------------------------------|
| strong_start_release:echo             | Prints a "Hello" message to the console. Verifies that the gem is functional.                                         |
| strong_start_release:aws:verify       | Verify that AWS credentials are available for build and deploy. Returns information about the AWS account being used. |
| strongstart_release:build             | Build a release for the including app (SiTE SOURCE or GRFS)                                                           |
| strongstart_release:deploy:staging    | Deploy the staging release for the including app (SiTE SOURCE or GRFS)                                                |
| strongstart_release:deploy:production | Deploy the production release for the including app (SiTE SOURCE or GRFS)                                             |

## Installation
1. Provide credentials that will be used by bundler to access GitHub packages to retrieve the gem.  Do this by configuring the bundler as follows:

```bash
    bundle config set --global https://rubygems.pkg.github.com/strong-start username:<your_github_personal access_token>
```

\<your_GitHub_personal access_token> must be the "classic" type of personal access token, not the modern "fine-grained" type (a GitHub Packages constraint). The token has the pattern /\Aghp_[a-zA-Z0-9]{36}\z/ and must have at least the "read:packages" scope. Normally you will be using a token that has both "read:packages" and "write:packages" scopes because you will also be developing the gem from time to time.
2. Add the following to your application's Gemfile:
```ruby
group :development do
  source "https://rubygems.pkg.github.com/strong-start" do
    gem 'strongstart_release', '~> 0.1.0'
  end
end
```
3. `bundle`

## Usage
You build and deploy to staging or production from a development instance. With the recommended installation, the gem is not even installed in staging or production.

### Example - build and deploy GRFS to staging

1. Start a terminal session in a GRFS development instance, at the Rails root.
2. `rails strongstart_release:build`
3. `rails strongstart_release:deploy:staging`

Note that the gem determines the app, SiTE SOURCE or GRFS, dynamically from the Rails app's file tree, by reading config/application.rb.

## Development

1. Configure the gem command so you can publish to GitHub Packages, by adding an entry to ~/.gem/credentials:

```aiignore
:github: Bearer <your_github_personal access_token>
```

"<your_GitHub_personal access_token>" must be the "classic" type of personal access token, not the modern "fine-grained" type (a GitHub Packages constraint). The token has the pattern /\Aghp_[a-zA-Z0-9]{36}\z/ and must have at the "read:packages" and "write:packages" scopes. Normally you will be using the same token that you used to configure the bundler (see above).

1. Make your changes to the code. Include updating the gem version number, in lib/strongstart_release/version.rb.

1`./build-and-publish`

1. Commit the change to "Gemfile.lock" that results from the build and publish.