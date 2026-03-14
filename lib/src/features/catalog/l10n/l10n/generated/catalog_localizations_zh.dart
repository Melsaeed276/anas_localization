// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'catalog_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class CatalogLocalizationsZh extends CatalogLocalizations {
  CatalogLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Anas 目录';

  @override
  String get refresh => '刷新';

  @override
  String get newString => '新字符串';

  @override
  String get createNewString => '创建新字符串';

  @override
  String get createNewStringSubtitle => '源语言排在第一位。已填写的目标语言在点击完成前仍需要审核。';

  @override
  String get keyPathLabel => '键路径';

  @override
  String get keyPathHint => 'checkout.summary.title';

  @override
  String get noteLabel => '键备注';

  @override
  String get noteHint => '添加给翻译者或审核者的上下文';

  @override
  String get create => '创建';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get themeLabel => '主题';

  @override
  String get themeSystem => '系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get catalogLanguage => '目录语言';

  @override
  String get searchLabel => '搜索';

  @override
  String get searchHint => '搜索键、值或备注';

  @override
  String get filterAll => '全部';

  @override
  String get filterReady => '就绪';

  @override
  String get filterNeedsReview => '需要审核';

  @override
  String get filterMissing => '缺失';

  @override
  String get keysLabel => '键';

  @override
  String get readyRowsLabel => '就绪行';

  @override
  String get reviewRowsLabel => '审核行';

  @override
  String get missingRowsLabel => '缺失行';

  @override
  String get noKeys => '未找到键。';

  @override
  String get noSelection => '选择一个键开始编辑。';

  @override
  String get sourceLabel => '源文本';

  @override
  String get sourceImpact => '源语言';

  @override
  String get sourceImpactBody => '编辑源文本会重新打开目标语言的审核。';

  @override
  String get editorLabel => '编辑器';

  @override
  String get done => '完成';

  @override
  String get deleteKey => '删除键';

  @override
  String get deleteValue => '删除值';

  @override
  String get advancedJson => '高级 JSON';

  @override
  String get advancedJsonHelp => '对不支持的结构使用原始 JSON。';

  @override
  String get syncClean => '已同步';

  @override
  String get syncDirty => '未保存';

  @override
  String get syncSaving => '保存中';

  @override
  String get syncSaved => '已保存';

  @override
  String get syncError => '保存失败';

  @override
  String get statusReady => '就绪';

  @override
  String get statusNeedsReview => '需要审核';

  @override
  String get statusMissing => '缺失';

  @override
  String get reasonSourceChanged => '源文本已更改';

  @override
  String get reasonSourceAdded => '源文本已添加';

  @override
  String get reasonSourceDeleted => '源文本已删除';

  @override
  String get reasonSourceDeletedReviewRequired => '源文本已删除，需要审核';

  @override
  String get reasonTargetMissing => '目标缺失';

  @override
  String get reasonNewKeyNeedsReview => '新键需要审核';

  @override
  String get reasonTargetUpdatedNeedsReview => '目标已更新，需要审核';

  @override
  String get blockerTranslationEmpty => '翻译为空。';

  @override
  String get blockerWaitAutosave => '请等待自动保存完成。';

  @override
  String get blockerFillBranches => '标记完成前请填写所有可见分支。';

  @override
  String get blockerMissingPlaceholders => '缺少占位符';

  @override
  String get notesSection => '备注';

  @override
  String get backLabel => '返回';

  @override
  String get loading => '正在加载目录…';

  @override
  String get retry => '重试';

  @override
  String get pendingLabel => '待处理';

  @override
  String get missingLabel => '缺失';

  @override
  String get allTargetsReady => '所有目标语言都已就绪。';

  @override
  String get reviewed => '已审核';

  @override
  String get optionalValueLabel => '可选初始值';

  @override
  String get addBranchLabel => '添加分支';

  @override
  String get saveFailed => '保存失败';

  @override
  String get selectLocaleLabel => '语言';

  @override
  String get displayOnlyLabel => '仅显示';

  @override
  String get invalidKeyPath => '请输入有效的点分键路径。';

  @override
  String get confirmCreateWithoutSource => '在没有源值的情况下创建此键吗？';

  @override
  String get deleteKeyConfirmation => '要从所有语言中删除此键吗？';

  @override
  String get deleteSourceValueConfirmation => '要删除源值吗？';

  @override
  String get deleteLocaleValueConfirmation => '要删除此语言的值吗？';

  @override
  String get translationLabel => '翻译';

  @override
  String get sourcePreviewLabel => '源预览';

  @override
  String get noteIndicator => '有备注';

  @override
  String get noNote => '还没有备注。';

  @override
  String get bootstrapError => '无法加载目录启动配置。';

  @override
  String get noteSaved => '备注已保存';

  @override
  String get noteAutosave => '备注会在短暂延迟后自动保存。';

  @override
  String get queueTitle => '翻译队列';

  @override
  String get sortLabel => '排序';

  @override
  String get sortAlphabetical => 'A-Z';

  @override
  String get sortNamespace => '命名空间';

  @override
  String get noKeysTitle => '还没有目录键';

  @override
  String get noKeysBody => '先创建第一条文案以开始翻译队列。';

  @override
  String get noResultsTitle => '没有匹配的键';

  @override
  String get noResultsBody => '请尝试其他搜索或清除当前筛选。';

  @override
  String get selectionPlaceholderTitle => '选择一个键';

  @override
  String get selectionPlaceholderBody => '从队列中选择一项，以查看备注、源上下文、语言和活动。';

  @override
  String get sectionEmpty => '此分组中没有键。';

  @override
  String get overviewSection => '概览';

  @override
  String get sourceContextSection => '源上下文';

  @override
  String get localesSection => '语言';

  @override
  String get detailsSection => '详情';

  @override
  String get contextSection => '目录上下文';

  @override
  String get activitySection => '活动';

  @override
  String get namespaceLabel => '命名空间';

  @override
  String localeProgress(int ready, int total) {
    return '$total 个目标语言中已有 $ready 个就绪';
  }

  @override
  String get placeholdersLabel => '占位符';

  @override
  String get noPlaceholders => '源值中没有占位符。';

  @override
  String get reviewPendingLocales => '审核待处理语言';

  @override
  String reviewPendingSuccess(int count) {
    return '已审核 $count 个待处理语言。';
  }

  @override
  String get sourceLocaleMeta => '源语言';

  @override
  String get fallbackLocaleMeta => '回退语言';

  @override
  String get formatMeta => '格式';

  @override
  String get stateFileMeta => '状态文件';

  @override
  String get activityEmpty => '此键还没有活动记录。';

  @override
  String get activityKeyCreated => '已创建键';

  @override
  String get activitySourceUpdated => '源内容已更新';

  @override
  String get activityTargetUpdated => '翻译已更新';

  @override
  String get activityNoteUpdated => '备注已更新';

  @override
  String get activityLocaleReviewed => '语言已标记完成';

  @override
  String get activityValueDeleted => '值已删除';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class CatalogLocalizationsZhCn extends CatalogLocalizationsZh {
  CatalogLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => 'Anas 目录';

  @override
  String get refresh => '刷新';

  @override
  String get newString => '新字符串';

  @override
  String get createNewString => '创建新字符串';

  @override
  String get createNewStringSubtitle => '源语言排在第一位。已填写的目标语言在点击完成前仍需要审核。';

  @override
  String get keyPathLabel => '键路径';

  @override
  String get keyPathHint => 'checkout.summary.title';

  @override
  String get noteLabel => '键备注';

  @override
  String get noteHint => '添加给翻译者或审核者的上下文';

  @override
  String get create => '创建';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get themeLabel => '主题';

  @override
  String get themeSystem => '系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get catalogLanguage => '目录语言';

  @override
  String get searchLabel => '搜索';

  @override
  String get searchHint => '搜索键、值或备注';

  @override
  String get filterAll => '全部';

  @override
  String get filterReady => '就绪';

  @override
  String get filterNeedsReview => '需要审核';

  @override
  String get filterMissing => '缺失';

  @override
  String get keysLabel => '键';

  @override
  String get readyRowsLabel => '就绪行';

  @override
  String get reviewRowsLabel => '审核行';

  @override
  String get missingRowsLabel => '缺失行';

  @override
  String get noKeys => '未找到键。';

  @override
  String get noSelection => '选择一个键开始编辑。';

  @override
  String get sourceLabel => '源文本';

  @override
  String get sourceImpact => '源语言';

  @override
  String get sourceImpactBody => '编辑源文本会重新打开目标语言的审核。';

  @override
  String get editorLabel => '编辑器';

  @override
  String get done => '完成';

  @override
  String get deleteKey => '删除键';

  @override
  String get deleteValue => '删除值';

  @override
  String get advancedJson => '高级 JSON';

  @override
  String get advancedJsonHelp => '对不支持的结构使用原始 JSON。';

  @override
  String get syncClean => '已同步';

  @override
  String get syncDirty => '未保存';

  @override
  String get syncSaving => '保存中';

  @override
  String get syncSaved => '已保存';

  @override
  String get syncError => '保存失败';

  @override
  String get statusReady => '就绪';

  @override
  String get statusNeedsReview => '需要审核';

  @override
  String get statusMissing => '缺失';

  @override
  String get reasonSourceChanged => '源文本已更改';

  @override
  String get reasonSourceAdded => '源文本已添加';

  @override
  String get reasonSourceDeleted => '源文本已删除';

  @override
  String get reasonSourceDeletedReviewRequired => '源文本已删除，需要审核';

  @override
  String get reasonTargetMissing => '目标缺失';

  @override
  String get reasonNewKeyNeedsReview => '新键需要审核';

  @override
  String get reasonTargetUpdatedNeedsReview => '目标已更新，需要审核';

  @override
  String get blockerTranslationEmpty => '翻译为空。';

  @override
  String get blockerWaitAutosave => '请等待自动保存完成。';

  @override
  String get blockerFillBranches => '标记完成前请填写所有可见分支。';

  @override
  String get blockerMissingPlaceholders => '缺少占位符';

  @override
  String get notesSection => '备注';

  @override
  String get backLabel => '返回';

  @override
  String get loading => '正在加载目录…';

  @override
  String get retry => '重试';

  @override
  String get pendingLabel => '待处理';

  @override
  String get missingLabel => '缺失';

  @override
  String get allTargetsReady => '所有目标语言都已就绪。';

  @override
  String get reviewed => '已审核';

  @override
  String get optionalValueLabel => '可选初始值';

  @override
  String get addBranchLabel => '添加分支';

  @override
  String get saveFailed => '保存失败';

  @override
  String get selectLocaleLabel => '语言';

  @override
  String get displayOnlyLabel => '仅显示';

  @override
  String get invalidKeyPath => '请输入有效的点分键路径。';

  @override
  String get confirmCreateWithoutSource => '在没有源值的情况下创建此键吗？';

  @override
  String get deleteKeyConfirmation => '要从所有语言中删除此键吗？';

  @override
  String get deleteSourceValueConfirmation => '要删除源值吗？';

  @override
  String get deleteLocaleValueConfirmation => '要删除此语言的值吗？';

  @override
  String get translationLabel => '翻译';

  @override
  String get sourcePreviewLabel => '源预览';

  @override
  String get noteIndicator => '有备注';

  @override
  String get noNote => '还没有备注。';

  @override
  String get bootstrapError => '无法加载目录启动配置。';

  @override
  String get noteSaved => '备注已保存';

  @override
  String get noteAutosave => '备注会在短暂延迟后自动保存。';

  @override
  String get queueTitle => '翻译队列';

  @override
  String get sortLabel => '排序';

  @override
  String get sortAlphabetical => 'A-Z';

  @override
  String get sortNamespace => '命名空间';

  @override
  String get noKeysTitle => '还没有目录键';

  @override
  String get noKeysBody => '先创建第一条文案以开始翻译队列。';

  @override
  String get noResultsTitle => '没有匹配的键';

  @override
  String get noResultsBody => '请尝试其他搜索或清除当前筛选。';

  @override
  String get selectionPlaceholderTitle => '选择一个键';

  @override
  String get selectionPlaceholderBody => '从队列中选择一项，以查看备注、源上下文、语言和活动。';

  @override
  String get sectionEmpty => '此分组中没有键。';

  @override
  String get overviewSection => '概览';

  @override
  String get sourceContextSection => '源上下文';

  @override
  String get localesSection => '语言';

  @override
  String get detailsSection => '详情';

  @override
  String get contextSection => '目录上下文';

  @override
  String get activitySection => '活动';

  @override
  String get namespaceLabel => '命名空间';

  @override
  String localeProgress(int ready, int total) {
    return '$total 个目标语言中已有 $ready 个就绪';
  }

  @override
  String get placeholdersLabel => '占位符';

  @override
  String get noPlaceholders => '源值中没有占位符。';

  @override
  String get reviewPendingLocales => '审核待处理语言';

  @override
  String reviewPendingSuccess(int count) {
    return '已审核 $count 个待处理语言。';
  }

  @override
  String get sourceLocaleMeta => '源语言';

  @override
  String get fallbackLocaleMeta => '回退语言';

  @override
  String get formatMeta => '格式';

  @override
  String get stateFileMeta => '状态文件';

  @override
  String get activityEmpty => '此键还没有活动记录。';

  @override
  String get activityKeyCreated => '已创建键';

  @override
  String get activitySourceUpdated => '源内容已更新';

  @override
  String get activityTargetUpdated => '翻译已更新';

  @override
  String get activityNoteUpdated => '备注已更新';

  @override
  String get activityLocaleReviewed => '语言已标记完成';

  @override
  String get activityValueDeleted => '值已删除';
}
