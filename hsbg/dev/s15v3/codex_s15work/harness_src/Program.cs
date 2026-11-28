using MoonSharp.Interpreter;
using MoonSharp.Interpreter.Serialization.Json;
class P {
  static int Main(string[] a){
    var s = new Script(CoreModules.Preset_SoftSandbox);
    s.Globals["__dostring"] = DynValue.NewCallback((ctx, args) => {
      var code = args[0].String; var env = args[1].Table; var name = args[2].String;
      try { return s.DoString(code, env, name); }
      catch (InterpreterException e) { throw new ScriptRuntimeException(e.DecoratedMessage ?? e.Message); }
    });
    s.Globals["__readfile"] = DynValue.NewCallback((ctx, args) => DynValue.NewString(File.ReadAllText(args[0].String)));
    try {
      foreach (var f in a) s.DoString(File.ReadAllText(f), null, Path.GetFileName(f));
    } catch (InterpreterException e) { Console.WriteLine("HARNESS ERROR: " + (e.DecoratedMessage ?? e.Message)); return 2; }
    return 0;
  }
}
