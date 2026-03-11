/// ChineseUtils - 簡繁轉換工具
/// 提供基於內建對照表的基礎轉換功能
class ChineseUtils {
  ChineseUtils._();

  // 簡繁對照表 (擴充版，涵蓋更多常用字)
  static const String _s = "万与丑专业丛东丝丢两严丧个丰临为丽举么义乌乐乔习乡书买乱争于亏云亘亚产亩亮仑们仓产伙们仑仓俭储伦侦伪侥侣倾债值倾假偿傧储催傲仅儿党兰关兹养兽内冈册写军农冢冬冯冰冲决况冷冻净凄凉凌减凑凛几击凼凿剩划别删利刽刿剀剂剁剐剑剧劝办务劢动励劲劳势勋勐勾匆匀包匆匀化协却卫却县卷卸卺厅历厉压厕厌厍厕厌厨厢厣厦厨厢县县参双发变叙叠叶号叹叽吃各吓吁吆咝哗响哎哏哐哒哗响哎哏哐哒唤唢啧嘘嘤唤唢啧嘘嘤嚣嚣团园围囵图圆圣圣在场地坂均坎坝坛坂均坎坝坠声处备备复多夜够复多夜够大天太夫央失头夸夹夺奋斗奂奥奥夺奋斗女奴奶她如妃妄妆妇妈妍妒妓妖妙妥妨姆妮妲姐姑姓委姿威娃娄娅娆娇娘娜娟娣娥娩娱娶婆婉婪婊婕娼婚婢婵婷媛媚嫁嫂嫉嫌嫖嫡嫩嫣嬉嬉子孑孔孕字存孙孛孜孝孟孢季孤学孩孪孙孽它宅宇守安宋完宏宓宕宗官宙定宛宜宝实宠审宪宫宰宵容宽宾宿寂寄寅密富寒寓寐察寡寤寥寨寰宝实宠审宪寸对寻导寿封射将尉尊小少尔尖尘尚尝尢尤尬就尸尹尺尼尽尾尿局屁层居屈屋屎屏屑展屠属屡履层履属屠屡属屯山岁岂屹屿岁岂屹屿岚岛岭岳峡崆崇崎崭崔崆崇崎崭崔这是个";
  static const String _t = "萬與醜專業叢東絲丟兩嚴喪個豐臨為麗舉麼義烏樂喬習鄉書買亂爭於虧雲亙亞產畝亮侖們倉產夥們侖倉儉儲倫偵偽僥侶傾債值傾假償儐儲催傲僅兒黨蘭關茲養獸內岡冊寫軍農塚冬馮冰衝決況冷凍淨淒涼凌減湊凜幾擊氹鑿剩劃別刪利劊剮剴劑剁剮劍劇勸辦務劢動勵勁勞勢勳猛勾匆勻包匆勻化協卻衛卻縣卷卸卺廳歷厲壓廁厭厙廁厭廚廂厴廈廚廂縣縣參雙發變敘疊葉號嘆嘰吃各嚇籲吆絲嘩響哎哏哐噠嘩響哎哏哐噠喚嗩嘖噓嚶喚嗩嘖噓嚶囂囂團園圍圇圖圓聖聖在場地坂均坎壩壇坂均坎壩墜聲處備備復多夜夠復多夜夠大天太夫央失頭誇夾奪奮鬥奐奧奧奪奮鬥女奴奶她如妃妄妝婦媽妍妒妓妖妙妥妨姆妮妲姐姑姓委姿威娃婁婭嬈嬌娘娜娟娣娥娩娛娶婆婉婪婊婕娼婚婢嬋婷媛媚嫁嫂嫉嫌嫖嫡嫩嫣嬉嬉子孑孔孕字存孫孛孜孝孟孢季孤學孩孿孫孽它宅宇守安宋完宏宓宕宗官宙定宛宜寶實寵審憲宮宰宵容寬賓宿寂寄寅密富寒寓寐察寡寤寥寨寰寶實寵審憲寸對尋導壽封射將尉尊小少爾尖塵尚嘗尢尤尬就屍尹尺尼盡尾尿局屁層居屈屋屎屏屑展屠屬屢履層履屬屠屢屬屯山歲豈屹嶼歲豈屹嶼嵐島嶺岳峽崆崇崎嶄崔崆崇崎嶄崔這是个";

  static final Map<String, String> _s2tTable = {};
  static final Map<String, String> _t2sTable = {};

  static void _init() {
    if (_s2tTable.isNotEmpty) return;
    for (int i = 0; i < _s.length && i < _t.length; i++) {
      _s2tTable[_s[i]] = _t[i];
      _t2sTable[_t[i]] = _s[i];
    }
  }

  /// 簡體轉繁體
  static String s2t(String text) {
    _init();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(_s2tTable[char] ?? char);
    }
    return buffer.toString();
  }

  /// 繁體轉簡體
  static String t2s(String text) {
    _init();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      buffer.write(_t2sTable[char] ?? char);
    }
    return buffer.toString();
  }
}
