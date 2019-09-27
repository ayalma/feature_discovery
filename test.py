import subprocess
import json
args = ['flutter', 'pub', 'global', 'run', 'pana',
        '--source', 'path', '.', '--scores', '--no-warning']
process = subprocess.run(
    args, 
    capture_output=True,
    shell=True,
    text=True,
    check=True
)
for out in [process.stdout, process.stderr]:
    if out != None:
        for line in out.split("\n"): print(line)
output = json.loads(process.stdout)
health_score = output["scores"]["health"]
maintenance_score = output["scores"]["maintenance"]
print("health score ")
print(type(health_score))
print(health_score)
