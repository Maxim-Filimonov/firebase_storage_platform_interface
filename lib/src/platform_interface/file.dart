// abstract file interface
abstract class File {
  // gets filename
  get filename => throw new UnimplementedError();

  // gets filepath
  get path => null;

  // checks for existance of file
  bool existsSync() {
    throw new UnimplementedError();
  }
}
