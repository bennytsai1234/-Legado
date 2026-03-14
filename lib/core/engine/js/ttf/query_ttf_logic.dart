import 'dart:typed_data';
import 'buffer_reader.dart';
import 'ttf_tables.dart';
import 'query_ttf_base.dart';

/// QueryTTF 的表解析邏輯擴展
extension QueryTTFLogic on QueryTTFBase {
  void readHeadTable(Uint8List buffer) {
    var d = directorys['head'];
    if (d == null) return;
    var reader = BufferReader(buffer, d.offset);
    reader.position(d.offset + 50);
    headIndexToLocFormat = reader.readInt16();
  }

  void readMaxpTable(Uint8List buffer) {
    var d = directorys['maxp'];
    if (d == null) return;
    var reader = BufferReader(buffer, d.offset);
    reader.readUInt32(); // version
    maxpNumGlyphs = reader.readUInt16();
    maxpMaxContours = reader.readUInt16();
  }

  void readLocaTable(Uint8List buffer) {
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

  void readCmapTable(Uint8List buffer) {
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

  void readGlyfTable(Uint8List buffer) {
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
}
