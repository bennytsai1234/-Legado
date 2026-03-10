import 'dart:typed_data';

class BufferReader {
  final ByteData byteData;
  int _position;

  BufferReader(Uint8List bytes, [this._position = 0])
      : byteData = ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes);

  void position(int index) {
    _position = index;
  }

  int get currentPosition => _position;

  int readUInt32() {
    final val = byteData.getUint32(_position, Endian.big);
    _position += 4;
    return val;
  }

  int readInt32() {
    final val = byteData.getInt32(_position, Endian.big);
    _position += 4;
    return val;
  }

  int readUInt16() {
    final val = byteData.getUint16(_position, Endian.big);
    _position += 2;
    return val;
  }

  int readInt16() {
    final val = byteData.getInt16(_position, Endian.big);
    _position += 2;
    return val;
  }

  int readUInt8() {
    final val = byteData.getUint8(_position);
    _position += 1;
    return val;
  }

  int readInt8() {
    final val = byteData.getInt8(_position);
    _position += 1;
    return val;
  }

  Uint8List readByteArray(int len) {
    final list = Uint8List(len);
    for (int i = 0; i < len; i++) {
      list[i] = byteData.getUint8(_position + i);
    }
    _position += len;
    return list;
  }

  List<int> readUInt8Array(int len) {
    final list = List<int>.filled(len, 0);
    for (int i = 0; i < len; i++) {
      list[i] = byteData.getUint8(_position);
      _position += 1;
    }
    return list;
  }

  List<int> readInt16Array(int len) {
    final list = List<int>.filled(len, 0);
    for (int i = 0; i < len; i++) {
      list[i] = byteData.getInt16(_position, Endian.big);
      _position += 2;
    }
    return list;
  }

  List<int> readUInt16Array(int len) {
    final list = List<int>.filled(len, 0);
    for (int i = 0; i < len; i++) {
      list[i] = byteData.getUint16(_position, Endian.big);
      _position += 2;
    }
    return list;
  }

  List<int> readInt32Array(int len) {
    final list = List<int>.filled(len, 0);
    for (int i = 0; i < len; i++) {
      list[i] = byteData.getInt32(_position, Endian.big);
      _position += 4;
    }
    return list;
  }
}

class DirectoryEntry {
  String tableTag = '';
  int offset = 0;
  int length = 0;
}

class GlyfLayout {
  int numberOfContours = 0;
  int xMin = 0, yMin = 0, xMax = 0, yMax = 0;
  GlyphTableBySimple? glyphSimple;
  List<GlyphTableComponent>? glyphComponent;
}

class GlyphTableBySimple {
  List<int> endPtsOfContours = [];
  int instructionLength = 0;
  List<int> instructions = [];
  List<int> flags = [];
  List<int> xCoordinates = [];
  List<int> yCoordinates = [];
}

class GlyphTableComponent {
  int flags = 0;
  int glyphIndex = 0;
  int argument1 = 0;
  int argument2 = 0;
  double xScale = 1.0;
  double scale01 = 0.0;
  double scale10 = 0.0;
  double yScale = 1.0;
}

class QueryTTF {
  final Map<int, String> unicodeToGlyph = {};
  final Map<String, int> glyphToUnicode = {};
  final Map<int, int> unicodeToGlyphId = {};

  final Map<String, DirectoryEntry> directorys = {};
  int headIndexToLocFormat = 0;
  int maxpNumGlyphs = 0;
  int maxpMaxContours = 0;
  List<int> loca = [];
  List<GlyfLayout?> glyfArray = [];

  QueryTTF(Uint8List buffer) {
    var reader = BufferReader(buffer);
    reader.readUInt32(); // sfntVersion
    int numTables = reader.readUInt16();
    reader.readUInt16(); // searchRange
    reader.readUInt16(); // entrySelector
    reader.readUInt16(); // rangeShift

    for (int i = 0; i < numTables; ++i) {
      DirectoryEntry d = DirectoryEntry();
      var tagBytes = reader.readByteArray(4);
      d.tableTag = String.fromCharCodes(tagBytes);
      reader.readUInt32(); // checkSum
      d.offset = reader.readUInt32();
      d.length = reader.readUInt32();
      directorys[d.tableTag] = d;
    }

    _readHeadTable(buffer);
    _readMaxpTable(buffer);
    _readLocaTable(buffer);
    _readCmapTable(buffer);
    _readGlyfTable(buffer);

    for (var entry in unicodeToGlyphId.entries) {
      int u = entry.key;
      int gId = entry.value;
      if (gId >= glyfArray.length) continue;
      String? glyfString = getGlyfById(gId);
      if (glyfString != null) {
        unicodeToGlyph[u] = glyfString;
        glyphToUnicode[glyfString] = u;
      }
    }
  }

  void _readHeadTable(Uint8List buffer) {
    var d = directorys['head'];
    if (d == null) return;
    var reader = BufferReader(buffer, d.offset);
    reader.position(d.offset + 50);
    headIndexToLocFormat = reader.readInt16();
  }

  void _readMaxpTable(Uint8List buffer) {
    var d = directorys['maxp'];
    if (d == null) return;
    var reader = BufferReader(buffer, d.offset);
    reader.readUInt32(); // version
    maxpNumGlyphs = reader.readUInt16();
    maxpMaxContours = reader.readUInt16();
  }

  void _readLocaTable(Uint8List buffer) {
    var d = directorys['loca'];
    if (d == null) return;
    var reader = BufferReader(buffer, d.offset);
    if (headIndexToLocFormat == 0) {
      loca = reader.readUInt16Array(d.length ~/ 2);
      for (int i = 0; i < loca.length; i++) {
        loca[i] *= 2;
      }
    } else {
      loca = reader.readInt32Array(d.length ~/ 4);
    }
  }

  void _readCmapTable(Uint8List buffer) {
    var d = directorys['cmap'];
    if (d == null) return;
    var reader = BufferReader(buffer, d.offset);
    reader.readUInt16(); // version
    int numTables = reader.readUInt16();
    List<Map<String, int>> records = [];
    for (int i = 0; i < numTables; ++i) {
      records.add({
        'platformID': reader.readUInt16(),
        'encodingID': reader.readUInt16(),
        'offset': reader.readUInt32(),
      });
    }

    Set<int> parsedOffsets = {};
    for (var record in records) {
      int fmtOffset = record['offset']!;
      if (parsedOffsets.contains(fmtOffset)) continue;
      parsedOffsets.add(fmtOffset);
      reader.position(d.offset + fmtOffset);

      int format = reader.readUInt16();
      int length = reader.readUInt16();
      reader.readUInt16(); // language

      if (format == 0) {
        var glyphIdArray = reader.readUInt8Array(length - 6);
        for (int unicodeMap = 0; unicodeMap < glyphIdArray.length; unicodeMap++) {
          if (glyphIdArray[unicodeMap] != 0) {
            unicodeToGlyphId[unicodeMap] = glyphIdArray[unicodeMap];
          }
        }
      } else if (format == 4) {
        int segCountX2 = reader.readUInt16();
        int segCount = segCountX2 ~/ 2;
        reader.readUInt16(); // searchRange
        reader.readUInt16(); // entrySelector
        reader.readUInt16(); // rangeShift
        var endCode = reader.readUInt16Array(segCount);
        reader.readUInt16(); // reservedPad
        var startCode = reader.readUInt16Array(segCount);
        var idDelta = reader.readInt16Array(segCount);
        var idRangeOffsets = reader.readUInt16Array(segCount);
        int glyphIdArrayLength = (length - 16 - (segCount * 8)) ~/ 2;
        var glyphIdArray = reader.readUInt16Array(glyphIdArrayLength);

        for (int segmentIndex = 0; segmentIndex < segCount; segmentIndex++) {
          int unicodeInclusive = startCode[segmentIndex];
          int unicodeExclusive = endCode[segmentIndex];
          int delta = idDelta[segmentIndex];
          int offset = idRangeOffsets[segmentIndex];
          for (int unicodeMap = unicodeInclusive; unicodeMap <= unicodeExclusive; unicodeMap++) {
            int glyphId = 0;
            if (offset == 0) {
              glyphId = (unicodeMap + delta) & 0xFFFF;
            } else {
              int gIndex = (offset ~/ 2) + unicodeMap - unicodeInclusive + segmentIndex - segCount;
              if (gIndex < glyphIdArrayLength) {
                glyphId = (glyphIdArray[gIndex] + delta) & 0xFFFF;
              }
            }
            if (glyphId != 0 && unicodeMap != 0xFFFF) {
              unicodeToGlyphId[unicodeMap] = glyphId;
            }
          }
        }
      } else if (format == 6) {
        int firstCode = reader.readUInt16();
        int entryCount = reader.readUInt16();
        var glyphIdArray = reader.readUInt16Array(entryCount);
        int unicodeMap = firstCode;
        for (int gIndex = 0; gIndex < entryCount; gIndex++) {
          if (glyphIdArray[gIndex] != 0) {
            unicodeToGlyphId[unicodeMap] = glyphIdArray[gIndex];
          }
          unicodeMap++;
        }
      }
    }
  }

  void _readGlyfTable(Uint8List buffer) {
    var d = directorys['glyf'];
    if (d == null) return;
    glyfArray = List<GlyfLayout?>.filled(maxpNumGlyphs, null);
    var reader = BufferReader(buffer);

    for (int index = 0; index < maxpNumGlyphs; index++) {
      if (index + 1 < loca.length && loca[index] == loca[index + 1]) continue;
      int offset = d.offset + loca[index];
      reader.position(offset);

      var glyph = GlyfLayout();
      glyph.numberOfContours = reader.readInt16();
      if (glyph.numberOfContours > maxpMaxContours) continue;
      glyph.xMin = reader.readInt16();
      glyph.yMin = reader.readInt16();
      glyph.xMax = reader.readInt16();
      glyph.yMax = reader.readInt16();

      if (glyph.numberOfContours == 0) continue;

      if (glyph.numberOfContours > 0) {
        glyph.glyphSimple = GlyphTableBySimple();
        glyph.glyphSimple!.endPtsOfContours = reader.readUInt16Array(glyph.numberOfContours);
        glyph.glyphSimple!.instructionLength = reader.readUInt16();
        glyph.glyphSimple!.instructions = reader.readUInt8Array(glyph.glyphSimple!.instructionLength);
        int flagLength = glyph.glyphSimple!.endPtsOfContours.isEmpty ? 0 : glyph.glyphSimple!.endPtsOfContours.last + 1;
        glyph.glyphSimple!.flags = List<int>.filled(flagLength, 0);

        for (int n = 0; n < flagLength; ++n) {
          int flag = reader.readUInt8();
          glyph.glyphSimple!.flags[n] = flag;
          if ((flag & 0x08) == 0x08) {
            int repeats = reader.readUInt8();
            for (int m = repeats; m > 0; --m) {
              glyph.glyphSimple!.flags[++n] = flag;
            }
          }
        }

        glyph.glyphSimple!.xCoordinates = List<int>.filled(flagLength, 0);
        for (int n = 0; n < flagLength; ++n) {
          int flag = glyph.glyphSimple!.flags[n];
          switch (flag & 0x12) {
            case 0x02:
              glyph.glyphSimple!.xCoordinates[n] = -reader.readUInt8();
              break;
            case 0x12:
              glyph.glyphSimple!.xCoordinates[n] = reader.readUInt8();
              break;
            case 0x10:
              glyph.glyphSimple!.xCoordinates[n] = 0;
              break;
            case 0x00:
              glyph.glyphSimple!.xCoordinates[n] = reader.readInt16();
              break;
          }
        }

        glyph.glyphSimple!.yCoordinates = List<int>.filled(flagLength, 0);
        for (int n = 0; n < flagLength; ++n) {
          int flag = glyph.glyphSimple!.flags[n];
          switch (flag & 0x24) {
            case 0x04:
              glyph.glyphSimple!.yCoordinates[n] = -reader.readUInt8();
              break;
            case 0x24:
              glyph.glyphSimple!.yCoordinates[n] = reader.readUInt8();
              break;
            case 0x20:
              glyph.glyphSimple!.yCoordinates[n] = 0;
              break;
            case 0x00:
              glyph.glyphSimple!.yCoordinates[n] = reader.readInt16();
              break;
          }
        }
      } else {
        glyph.glyphComponent = [];
        while (true) {
          var comp = GlyphTableComponent();
          comp.flags = reader.readUInt16();
          comp.glyphIndex = reader.readUInt16();
          switch (comp.flags & 0x03) {
            case 0x00:
              comp.argument1 = reader.readUInt8();
              comp.argument2 = reader.readUInt8();
              break;
            case 0x02:
              comp.argument1 = reader.readInt8();
              comp.argument2 = reader.readInt8();
              break;
            case 0x01:
              comp.argument1 = reader.readUInt16();
              comp.argument2 = reader.readUInt16();
              break;
            case 0x03:
              comp.argument1 = reader.readInt16();
              comp.argument2 = reader.readInt16();
              break;
          }
          switch (comp.flags & 0xC8) {
            case 0x08:
              comp.yScale = comp.xScale = reader.readInt16() / 16384.0;
              break;
            case 0x40:
              comp.xScale = reader.readInt16() / 16384.0;
              comp.yScale = reader.readInt16() / 16384.0;
              break;
            case 0x80:
              comp.xScale = reader.readInt16() / 16384.0;
              comp.scale01 = reader.readInt16() / 16384.0;
              comp.scale10 = reader.readInt16() / 16384.0;
              comp.yScale = reader.readInt16() / 16384.0;
              break;
          }
          glyph.glyphComponent!.add(comp);
          if ((comp.flags & 0x20) == 0) break;
        }
      }
      glyfArray[index] = glyph;
    }
  }

  String? getGlyfById(int glyfId) {
    if (glyfId >= glyfArray.length) return null;
    var glyph = glyfArray[glyfId];
    if (glyph == null) return null;
    if (glyph.numberOfContours >= 0) {
      if (glyph.glyphSimple == null) return null;
      List<String> coords = [];
      for (int i = 0; i < glyph.glyphSimple!.xCoordinates.length; i++) {
        coords.add("${glyph.glyphSimple!.xCoordinates[i]},${glyph.glyphSimple!.yCoordinates[i]}");
      }
      return coords.join("|");
    } else {
      if (glyph.glyphComponent == null) return null;
      List<String> comps = [];
      for (var g in glyph.glyphComponent!) {
        comps.add("{flags:${g.flags},glyphIndex:${g.glyphIndex},arg1:${g.argument1},arg2:${g.argument2},xScale:${g.xScale},scale01:${g.scale01},scale10:${g.scale10},yScale:${g.yScale}}");
      }
      return "[${comps.join(",")}]";
    }
  }

  int getGlyfIdByUnicode(int unicode) {
    return unicodeToGlyphId[unicode] ?? 0;
  }

  String? getGlyfByUnicode(int unicode) {
    return unicodeToGlyph[unicode];
  }

  int getUnicodeByGlyf(String? glyph) {
    if (glyph == null) return 0;
    return glyphToUnicode[glyph] ?? 0;
  }

  bool isBlankUnicode(int unicode) {
    switch (unicode) {
      case 0x0009:
      case 0x0020:
      case 0x00A0:
      case 0x2002:
      case 0x2003:
      case 0x2007:
      case 0x200A:
      case 0x200B:
      case 0x200C:
      case 0x200D:
      case 0x202F:
      case 0x205F:
        return true;
      default:
        return false;
    }
  }
}
