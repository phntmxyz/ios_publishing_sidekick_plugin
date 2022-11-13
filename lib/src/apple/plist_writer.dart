import 'package:xml/xml.dart' as xml;

extension PlistOnStringExt on Map<String, dynamic> {
  String asPlist() {
    return PListWriter().write(this);
  }
}

class PListWriter {
  static const skeleton = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
</plist>
""";

  String write(Map<String, dynamic> values) {
    final doc = xml.XmlDocument.parse(skeleton);
    final plist = doc.findAllElements('plist').first;
    plist.addDictionary(values);
    return doc.toXmlString(pretty: true);
  }
}

extension PlistXmlBuilderExt on xml.XmlElement {
  void addValue(dynamic value) {
    if (value is String) {
      children.add(xml.XmlElement(xml.XmlName('string'), [], [xml.XmlText(value)]));
    } else if (value is int) {
      children.add(xml.XmlElement(xml.XmlName('integer'), [], [xml.XmlText(value.toString())]));
    } else if (value is double) {
      children.add(xml.XmlElement(xml.XmlName('real'), [], [xml.XmlText(value.toString())]));
    } else if (value is bool) {
      if (value) {
        children.add(xml.XmlElement(xml.XmlName('true')));
      } else {
        children.add(xml.XmlElement(xml.XmlName('false')));
      }
    } else {
      throw 'unsupported type ${value.runtimeType}';
    }
  }

  void addArray(List<dynamic> list) {
    final array = xml.XmlElement(xml.XmlName('array'));
    for (final item in list) {
      array.addValue(item);
    }
    children.add(array);
  }

  void addDictionary(Map<dynamic, dynamic> map) {
    final dict = xml.XmlElement(xml.XmlName('dict'));
    for (final entry in map.entries) {
      final key = entry.key as String;
      dict.children.add(xml.XmlElement(xml.XmlName('key'), [], [xml.XmlText(key)]));

      final value = entry.value;
      if (value is Map<dynamic, dynamic>) {
        dict.addDictionary(value);
      } else if (value is List<dynamic>) {
        dict.addArray(value);
      } else {
        dict.addValue(value);
      }
    }
    children.add(dict);
  }
}
