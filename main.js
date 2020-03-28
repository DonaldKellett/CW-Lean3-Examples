const child_process = require('child_process');

child_process.exec('cd src/ && lean SolutionTest.lean', (error, stdout, stderr) => {
  if (error) {
    console.error(`Error during command execution: ${error}`);
    return;
  }
  let lines = stdout.split`\n`.filter(x => x);
  const ALLOWED = ['no axioms', 'propext', 'quot.sound', 'classical.choice'];
  let forbidden = [];
  for (let line of lines)
    if (!ALLOWED.includes(line))
      forbidden.push(line);
  if (forbidden.length === 0)
    console.log('<PASSED::>No forbidden axioms');
  else {
    let failMsg = '<FAILED::>Forbidden axioms:';
    for (let axiom of forbidden)
      failMsg += `<:LF:>  ${axiom}`;
    console.log(failMsg);
  }
  console.error('STDERR:\n' + stderr);
});
