const sys = require("child_process");

sys.exec("cd kata/src/; lean SolutionTest.lean", (error, stdout, stderr) => {
  if (error) {
    console.log(`FATAL ERROR:\n${error.message}`);
    return;
  }
  if (stderr) {
    console.log(`STDERR:\n${stderr}`);
    return;
  }
  const ALLOWED_AXIOMS = [
    "no axioms",
    "propext",
    "quot.sound",
    "classical.choice"
  ];
  let lines = stdout
    .split("\n")
    .filter(x => x)
    .map(x => ALLOWED_AXIOMS.includes(x) ?
      `<PASSED::>${x}\n` :
      `<FAILED::>${x}\n`);
  console.log(lines.join``);
});
