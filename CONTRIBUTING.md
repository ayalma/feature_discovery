# Steps

The following steps are based on [creativecreatorormaybenot/wakelock's contributing guide](https://github.com/creativecreatorormaybenot/wakelock/blob/3c15a42cc25d67ade003a3ce3fc4c84cf3d02b8a/CONTRIBUTING.md).

## Creating a fork

 * If you have not yet configured your machine with an SSH key that is known to GitHub, then follow [GitHub's directions](https://help.github.com/articles/generating-ssh-keys/) to generate an SSH key.
 * Fork [this repository](https://github.com/ayalma/feature_discovery) using the "Fork" button in the upper right corner of the repository's GitHub page.
 * `git clone git@github.com:<github_user_name>/feature_discovery.git`
 * `cd feature_discovery`
 * `git remote add upstream git@github.com:/ayalma/feature_discovery.git`  
   This ensures that `git fetch upstream` is possible to fetch from this remote repository instead of from your own fork to get the latest changes.
   
## Creating a patch

 * `git fetch upstream`
 * `git checkout upstream/master -b <name_of_your_branch>`
 * Now, you can change the code necessary for your patch.
 
   Make sure that you bump the version in [`pubspec.yaml`](https://github.com/ayalma/feature_discovery/blob/master/pubspec.yaml) 
   and add an entry to [`CHANGELOG.md`](https://github.com/ayalma/feature_discovery/blob/master/CHANGELOG.md).  
   The version format is `r.M.m+p`. You will want to increment one of these values and which one you increment depends on the impact of your patch: 
   `p` for simple patches, `m` for minor versions, `M` for major versions, and `r` for released. Do not forget to reset the values to the right of the value you incremented to 0. You should omit `+0`.
 * `git commit -am "<commit_message>"`
 * `git push origin <name_of_your_branch>`

After having followed these steps, you are ready to [create a pull request](https://help.github.com/en/articles/creating-a-pull-request-from-a-fork).  
The GitHub interface makes this very easy by providing a button on your fork page that creates a pull request with changes from a recently pushed to branch.  
Alternatively, you can also use `git pull-request` via [GitHub hub](https://hub.github.com/).

# Notes

 * You should remember to exclude all files and directories your IDE might generate using the `.gitignore` files (if they do not already contain them for your IDE).  
   If you feel like you can make useful additions to any of the `.gitignore` files, you can include them in your pull request, potentially with an explanation.

 * You should make sure that tests are not failing before opening a pull request using `flutter test` in the `feature_discovery` (root) directory. 
   This way you can ensure that any changes you have made work properly.  
   Furthermore, you should want to **add tests** if you implement new functionality.

 * You should also run `flutter dartfmt lib example test` (formatting all Dart files) in the root directory and make sure that `flutter analyze` does not report any errors.
 
 * Regarding the previous two steps, GitHub actions, i.e. continuous integration, will also perform tests, formatting, and analysis when you open a pull request.  
   Additionally, there is a GitHub action for Pub package analysis that will notify you when your pull request lowers the package's score.  
   This ensures that your changes do not introduce any issues and you should fix any errors that are detected.
