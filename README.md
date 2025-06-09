# StrongstartRelease

A private ruby gem that adds the following rake tasks to the development environment of a Strong Start web application - SiTE SOURCE or GRFS:

| Task                                  | Description                                                                                                                                                                                                             | Arguments              |
|---------------------------------------|----------------------------------------------------------------------|------------------------|
| strong_start_release:echo             | Prints a "Hello" message to the console. Verifies that the gem is functional.                                                                                                                                           |                        |
| strong_start_release:aws:verify       | Verify that AWS credentials are available for build and deploy. Returns information about the AWS account being used.                                                                                                   |                        |
| strongstart_release:build             | Build a release for the including app (SiTE SOURCE or GRFS). The image is the same for staging and production. Run-time behaviour is controlled by docker container environment variables configured during deployment. | --no-tests, --dry_run  |
| strongstart_release:deploy:staging    | Deploy the staging release for the including app (SiTE SOURCE or GRFS)                                                                                                                                                  | version_tag, --dry-run |
| strongstart_release:deploy:production | Deploy the production release for the including app (SiTE SOURCE or GRFS). Same docker image as the staging release, but different docker container. environment variables.                                             | version_tag, --dry_run |

**Note**
1. All arguments are optional. 
2. The version tag is to revert to an "old" version. Historically, this the need for this has been very rare. The version_tag argument is recognized by the pattern used by convention in our apps - text that ends in the well-known three-level semantic versioning pattern.If no version_tag is provided, the latest version is used.
3. If --dry-run is specified for build, the task will build the local docker image but will not push it to ECR. The task will not update the version in the repo but the version tag on the local docker image will be the version in the repo + 1. That is, it will be the version that would have been pushed without --dry-run.
3. If --dry_run is specified for deploy, the task will not actually deploy, but will relevant print information about the cluster, service and ECS task.

## Installation
1. Provide credentials that will be used by bundler to access GitHub packages to retrieve the gem.  Do this by configuring the bundler as follows:

```bash
    bundle config set --global https://rubygems.pkg.github.com/strong-start username:<your_github_personal access_token>
```

This will update (creating, if necessary) your ~/.bundle/config file. There are other ways to pass the credentials to the bundler, such as using an environment variable, but this config file approach is required in order for the build docker container to have the credentials needed to access GitHub Packages (see Note 2 under Usage below).

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

### Example 1 - build and deploy GRFS to staging

1. Start a terminal session in a GRFS development instance, at the Rails root.
2. `rails strongstart_release:build`
3. `rails strongstart_release:deploy:staging`

**Notes**
1. How do the rake tasks know if we want SiTE SOURCE or GRFS? The gem determines the app, SiTE SOURCE or GRFS, dynamically from the Rails app's file tree, by reading config/application.rb.
2. Why does the build task need ~/.bundle/config? The build task runs a docker build command that will bundle the app (SiTE SOURCE or GRFS) and requires credentials for GitHub packages, even though the Dockerfile bundling excludes strongstart_release in staging/production (in fact it excludes all gems named in the :development and/or :test groups). According to chatGPT (!) this is because the bundler retrieves metadata for all sources named in the Gemfile whether or not they will be bundled, in order to resolve dependencies. In any case, credentials for GitHub Packages do seem to be needed. We provide them by transferring the ~/.bundle/config file securely from the development instance to the docker build container with "RUN --mount=type=secret ...". 
3. Why is the baroque-seeming "RUN --mount=type=secret ..." more secure than the simpler approach of COPYing it into the docker context?  This method prevents the file from being persisted in intermediate image layers and also avoids the risk of accidentally committing the credentials to the development project's git repository. The file is only present in the build container while the build is running, and it is not included in the final image. This is reputed to be a best practice for handling sensitive information in Docker builds.

### Example 2 - build, but dry run

```aiignore
`rails "strongstart_release:build[--dry-run]"`
```

**Note**

The quotes are necessary in a shell to avoid the square brackets being mis-ininterpreted. Alternatively you can escape the opening "[" with a backslash.

### Example 3 - deploy, but dry run and specify a version tag

```aiignore
`rails "strongstart_release:deploy[--dry-run,main-25.1.42]"`
```

## Development

1. Configure the gem command so you can publish to GitHub Packages, by adding an entry to ~/.gem/credentials:

```aiignore
:github: Bearer <your_github_personal access_token>
```

"<your_GitHub_personal access_token>" must be the "classic" type of personal access token, not the modern "fine-grained" type (a GitHub Packages constraint). The token has the pattern /\Aghp_[a-zA-Z0-9]{36}\z/ and must have at the "read:packages" and "write:packages" scopes. Normally you will be using the same token that you used to configure the bundler (see above).

1. Make your changes to the code. Include updating the gem version number, in lib/strongstart_release/version.rb.

1`./build-and-publish`

1. Commit the change to "Gemfile.lock" that results from the build and publish.