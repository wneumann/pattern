import ArgumentParser

struct Pattern: ParsableCommand {
  private static let nums = Array("0123456789")
  private static let syms = Array("!@#$%^&*()_+-={}[]:;<>?,./~")
  private static let alphas = Array("abcdefghizklmnopqrstuvwxyz")
  private static let caps = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

  static var configuration = CommandConfiguration(
    abstract: "Generates patterns for use in reverse engineering.",
    version: "1.0.0",
    subcommands: [Create.self, Offset.self, Badchars.self],
    defaultSubcommand: Create.self)
}

struct Options: ParsableArguments {
  @Option(name: .long, help: "Length of generated pattern")
  var length: Int
}

extension Pattern {
  private static func create(length: Int) -> String {
    var charSets: [[Character]], indices: (Int) -> [Int]
    switch length {
    case 0...10:
      charSets = [Pattern.nums]
      indices = { [$0 % 10] }
    case 11...520:
      charSets = [Pattern.caps, Pattern.nums]
      indices = { (i: Int) in [(i / 10) % 26, i % 10] }
    case 521...20280:
      charSets = [Pattern.caps, Pattern.alphas, Pattern.nums]
      indices = { (i: Int) in [(i / 260) % 26, (i / 10) % 26, i % 10] }
    case 20280...730080:
      charSets = [Pattern.caps, Pattern.alphas, Pattern.syms, Pattern.nums]
      indices = { (i: Int) in [(i / 6760) % 27, (i / 260) % 26, (i / 10) % 26, i % 10] }
    default: fatalError("Invalid length. Length must be in the range 0...182520")
    }
    
    var cycle = "", remaining = length
    while remaining > 0 {
      let block = (length - remaining) / charSets.count, blocksize = min(remaining,charSets.count)
      let chIndices = indices(block)
      let chBlock = zip(charSets,chIndices).map { $0[$1] }.prefix(blocksize)
      cycle.append(contentsOf: chBlock)
      remaining -= blocksize
    }
    return cycle
  }

  struct Create: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Create pattern of specified length.")
    @OptionGroup var options: Options
    
    mutating func run() {
      print(create(length: options.length))
    }

  }
  
  struct Offset: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Locate a subpattern inside a pattern of specified length.")
    @OptionGroup var options: Options

    @Argument (help: "The pattern to search for.")
    var subPattern: String
    @Flag (help: "Supplied subpattern is a hex string rather than ASCII.")
    var hex = false

    private func findOffset(of location: String, in pattern: String, reversed: Bool = false) -> Int? {
      var slice = pattern[...], idx = 0
      let location = reversed ? String(location.reversed()) : location
      repeat {
        if slice.hasPrefix(location) { return idx }
        idx += 1
        slice = slice.dropFirst()
      } while !slice.isEmpty
      return nil
    }

    
    mutating func run() {
      let fullPattern = create(length: options.length)
      if hex || subPattern.hasPrefix("0x") || subPattern.hasPrefix("0X") {
        guard let ascii = Utils.hexToAscii(subPattern) else { print("\(subPattern) is not a valid hex representation of an ASCII string"); return }
        subPattern = ascii
      }
      
      if let offset = findOffset(of: subPattern, in: fullPattern) {
        print("\"\(subPattern)\" found at offset \(offset)")
      } else if let offset = findOffset(of: subPattern, in: fullPattern, reversed: true) {
        print("Reversed pattern \"\(String(subPattern.reversed()))\" found at offset \(offset)")
      } else {
        print("\"\(subPattern)\" not found")
      }
    }
    
  }
  
  struct Badchars: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Generate a string of potential bad characters")
//    @OptionGroup var options: Options

    @Option (name: .shortAndLong, help: "Bytes to exclude, in Mona style (e.g. \\x09\\x23\\xa0) or separated by spaces (e.g. 09 23 a0)")
    var exclude: String = ""

    mutating func run() {
      let split = exclude.hasPrefix("\\x") ? "\\x" : " "
      var excluded = Set(exclude.components(separatedBy: split).compactMap { UInt8($0, radix: 16) })
      excluded.insert(0)
      print("Excluded bytes: \"\(excluded.sorted().map { String(format: "\\x%02x", $0) }.joined())\"")
      print(((1 as UInt8)...255).map { byte in
        excluded.contains(byte) ? "" : "\\x\(String(format: "%02x", byte))"
      }.joined())
    }
  }
}

Pattern.main()
