const sys = require("child_process");

sys.exec("cd src/ && lean SolutionTest.lean -E SolutionTest.out && leanchecker SolutionTest.out submission", (error, stdout, stderr) => {
  if (error) {
    console.log("<ERROR::>There was an error checking your solution. Make sure your solution compiles and does not contain 'sorry'.\n");
    return;
  }
  if (stderr) {
    console.log(`STDERR:\n${stderr}`);
    return;
  }
  const ALLOWED_AXIOMS = [
    'axiom propext : Π {a b : Prop}, (a <-> b) -> a = b',
    'axiom classical.choice : Π {α : Sort u}, nonempty α -> α',
    'axiom quot.sound : Π {α : Sort u}, Π {r : α -> α -> Prop}, Π {a b : α}, r a b -> quot.mk r a = quot.mk r b'
  ];
  let forbidden = stdout
    .split("\n")
    .filter(x => /^axiom .*$/.test(x))
    .filter(x => !ALLOWED_AXIOMS.includes(x));
  if (forbidden.length > 0)
    console.log(`<FAILED::>Forbidden axioms detected:<:LF:>${forbidden.join`<:LF:>`}\n`);
  else
    console.log(`<PASSED::>No forbidden axioms\n`);
});