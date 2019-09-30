from github import Github
import subprocess
import json
import os
import sys
import textwrap


# Path of the package
path = sys.argv[1]
args = ['flutter', 'pub', 'global', 'run', 'pana',
        '--source', 'path', path, '--scores', '--no-warning']
use_shell = True
if use_shell:
    args = " ".join(args)
process = subprocess.run(args,
                         capture_output=True,
                         shell=use_shell,
                         text=True)
for out in [process.stderr, process.stdout]:
    if out != None:
        print("\n> ".join([line for line in out.split("\n")]))
code = process.returncode
# Don't go further if the command execution hasn't succeeded
if code != 0:
    raise RuntimeError('Process completed with exit code ' + str(code))
output = json.loads(process.stdout)


# Adding basic info
pana_version = output['runtimeInfo']['panaVersion']
health_score = output['scores']['health']
maintenance_score = output['scores']['maintenance']

# Adding suggestions to improve the scores
suggestions = None
if 'suggestions' in output:
    suggestions = '## Suggestions to improve the score:'
    for s in output['suggestions']:
        suggestions += '\n\n- **{} ({} points): **{}'.format(
            s['title'], str(s['score']), s['description'])

# Adding health issues
health_issues = []  # TODO(axel-op)


event = json.loads(os.environ['EVENT_PAYLOAD'])
if 'pull_request' in event:
    g = Github(os.environ['GITHUB_TOKEN'])
    repo = g.get_repo(event['repository']['id'], lazy=True)
    pr = repo.get_pull(event['pull_request']['number'])
    commit = event['pull_request']['head']['sha']
    comment = """   Package analysis results for commit {commit}:
    (version of [pana package](https://pub.dev/packages/pana): {version})

    Health score is {health_score} / 100.0
    Maintenance score is {maintenance_score} / 100.0{suggestions}
    """.format(
        version=str(pana_version),
        commit=str(commit),
        health_score=str(health_score),
        maintenance_score=str(maintenance_score),
        suggestions=('\n\n' + str(suggestions)) if suggestions != None else '')
    # Don't post comment if there is no problem
    if (health_score + maintenance_score < 200) or suggestions != None:
        pr.create_issue_comment(textwrap.dedent(comment))
