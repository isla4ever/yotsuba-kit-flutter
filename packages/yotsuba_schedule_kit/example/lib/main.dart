import 'package:flutter/material.dart';
import 'package:yotsuba_schedule_kit/yotsuba_schedule_kit.dart';

enum _CourseCardStyle { weather, none, shimmer, glow, aurora, breathe }

YsCardEffect _effectFor(_CourseCardStyle style) => switch (style) {
      _CourseCardStyle.weather || _CourseCardStyle.none => YsCardEffect.none,
      _CourseCardStyle.shimmer => YsCardEffect.shimmer,
      _CourseCardStyle.glow => YsCardEffect.glow,
      _CourseCardStyle.aurora => YsCardEffect.aurora,
      _CourseCardStyle.breathe => YsCardEffect.breathe,
    };

void main() => runApp(const YotsubaKitShowcase());

class YotsubaKitShowcase extends StatefulWidget {
  const YotsubaKitShowcase({super.key});

  @override
  State<YotsubaKitShowcase> createState() => _YotsubaKitShowcaseState();
}

class _YotsubaKitShowcaseState extends State<YotsubaKitShowcase> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yotsuba Schedule Kit',
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF357A64),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'YotsubaDemoSans',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF77B79F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'YotsubaDemoSans',
      ),
      home: _ShowcaseHome(
        dark: _dark,
        onDarkChanged: (value) => setState(() => _dark = value),
      ),
    );
  }
}

class _ShowcaseHome extends StatefulWidget {
  const _ShowcaseHome({
    required this.dark,
    required this.onDarkChanged,
  });

  final bool dark;
  final ValueChanged<bool> onDarkChanged;

  @override
  State<_ShowcaseHome> createState() => _ShowcaseHomeState();
}

class _ShowcaseHomeState extends State<_ShowcaseHome> {
  late final DateTime _termStart;
  late List<YsCourse> _courses;
  late YsWeatherSnapshot _weather;
  int _page = 0;
  int _week = 6;
  YsTransition _transition = YsTransition.wave;
  YsHeaderStyle _headerStyle = YsHeaderStyle.standard;
  YsScheduleDensity _density = YsScheduleDensity.normal;
  YsPalette _palette = YsPalette.morandi;
  _CourseCardStyle _courseCardStyle = _CourseCardStyle.weather;
  YsDetailLayout _detailLayout = YsDetailLayout.standard;
  YsDetailHero _detailHero = YsDetailHero.weather;
  YsSheetPlacement _detailPlacement = YsSheetPlacement.bottom;
  YsSheetPlacement _weekPlacement = YsSheetPlacement.center;
  bool _glass = true;
  bool _weatherScene = true;
  bool _reduceMotion = false;
  int _visibleDays = 7;
  List<YsTodayWidgetConfig> _todayWidgets = const [
    YsTodayWidgetConfig(
      id: YsTodayWidgetIds.nextCourse,
      size: YsTodayWidgetSize.compact,
    ),
    YsTodayWidgetConfig(
      id: YsTodayWidgetIds.weather,
      size: YsTodayWidgetSize.compact,
    ),
    YsTodayWidgetConfig(id: YsTodayWidgetIds.timeline),
    YsTodayWidgetConfig(
      id: YsTodayWidgetIds.readiness,
      size: YsTodayWidgetSize.oneByTwo,
    ),
    YsTodayWidgetConfig(id: YsTodayWidgetIds.plans),
    YsTodayWidgetConfig(id: YsTodayWidgetIds.courseTasks),
    YsTodayWidgetConfig(
      id: YsTodayWidgetIds.weekGlance,
      size: YsTodayWidgetSize.twoByTwo,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    _termStart = DateTime(monday.year, monday.month, monday.day)
        .subtract(const Duration(days: 35));
    _courses = _demoCourses();
    _weather = _demoWeather(today);
  }

  YsScheduleTheme get _kitTheme {
    final base = widget.dark ? YsScheduleTheme.dark : YsScheduleTheme.light;
    return base.copyWith(coursePalette: ysPaletteColors(_palette));
  }

  YsSheetConfig get _sheets => YsSheetConfig(
        placement: YsSheetPlacement.bottom,
        placements: {
          YsSheetKind.courseDetail: _detailPlacement,
          YsSheetKind.weekPicker: _weekPlacement,
          YsSheetKind.settings: YsSheetPlacement.right,
          YsSheetKind.dayPlanner: YsSheetPlacement.bottom,
        },
        glass: _glass,
        adjustable: true,
      );

  YsDayPlanMap get _plans {
    final today = formatDateKey(DateTime.now());
    return {
      today: const [
        YsDayPlan(id: 'review', text: '复习概率论第三章'),
        YsDayPlan(id: 'lab', text: '提交实验报告', done: true),
        YsDayPlan(id: 'club', text: '确认社团活动场地'),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final page = _page == 0 ? _schedulePage() : _todayPage();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration:
              _reduceMotion ? Duration.zero : const Duration(milliseconds: 320),
          reverseDuration:
              _reduceMotion ? Duration.zero : const Duration(milliseconds: 260),
          layoutBuilder: (currentChild, previousChildren) => Stack(
            fit: StackFit.expand,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild
            ],
          ),
          transitionBuilder: (child, animation) {
            final entering = child.key == ValueKey(_page);
            final direction = _page == 0 ? -1.0 : 1.0;
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(direction * (entering ? 0.025 : -0.015), 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(key: ValueKey(_page), child: page),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        tooltip: '设置',
        onPressed: _openSettings,
        child: const Icon(Icons.tune),
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _page,
        onDestinationSelected: (index) => setState(() => _page = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: '课表',
          ),
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '今日',
          ),
        ],
      ),
    );
  }

  Widget _schedulePage() {
    return YsSchedule(
      week: _week,
      totalWeeks: 20,
      courses: _courses,
      termStart: _termStart,
      onWeekChanged: (value) => setState(() => _week = value),
      visibleDays: _visibleDays,
      rowHeight: _density == YsScheduleDensity.minimal ? 50 : 58,
      theme: _kitTheme,
      headerStyle: _headerStyle,
      headerTitle: 'Yotsuba 课程表',
      headerActions: [
        YsHeaderAction(
          icon: Icons.file_download_outlined,
          label: '导出 ICS',
          onPressed: () => _notice('已生成一份 ICS 日历文件'),
        ),
        YsHeaderAction(
          icon: Icons.share_outlined,
          label: '分享课表',
          onPressed: () => _notice('已生成课表分享内容'),
        ),
        YsHeaderAction(
          icon: Icons.sync_alt,
          label: '同步系统日历',
          onPressed: () => _notice('已请求同步到系统日历'),
        ),
      ],
      transition: _transition,
      density: _density,
      cardEffect: _effectFor(_courseCardStyle),
      weatherCardBackground: _courseCardStyle == _CourseCardStyle.weather,
      reduceMotion: _reduceMotion,
      weather: _weather,
      weatherScene: _weatherScene,
      detail: YsCourseDetailConfig(
        layout: _detailLayout,
        hero: _detailHero,
      ),
      sheets: _sheets,
      onHeaderStyleChanged: (value) => setState(() => _headerStyle = value),
      onDetailLayoutChanged: (value) => setState(() => _detailLayout = value),
      onWeatherTap: _openWeather,
      onDayTap: (weekday, date) {
        if (date != null) _openDay(date);
      },
      onCourseShare: (_) => _notice('课程卡片已准备分享'),
      onCourseEdit: (course) => _notice('编辑：${course.course.name}'),
      onCourseRemove: _removeCourse,
    );
  }

  Widget _todayPage() {
    return YsToday(
      courses: _courses,
      termStart: _termStart,
      totalWeeks: 20,
      widgets: _todayWidgets,
      dayPlans: _plans,
      weather: _weather,
      theme: _kitTheme,
      weatherScene: _weatherScene,
      reduceMotion: _reduceMotion,
      onWidgetsChanged: (value) => setState(() => _todayWidgets = value),
      onCourseTap: (course) => _notice(course.course.name),
    );
  }

  Future<void> _openSettings() {
    return showYsAdaptiveSheet<void>(
      context: context,
      title: '演示设置',
      icon: Icons.tune,
      kind: YsSheetKind.settings,
      theme: _kitTheme,
      config: _sheets,
      builder: (context, placement) => _SettingsPanel(
        dark: widget.dark,
        transition: _transition,
        headerStyle: _headerStyle,
        density: _density,
        palette: _palette,
        courseCardStyle: _courseCardStyle,
        detailLayout: _detailLayout,
        detailHero: _detailHero,
        detailPlacement: _detailPlacement,
        weekPlacement: _weekPlacement,
        glass: _glass,
        weatherScene: _weatherScene,
        reduceMotion: _reduceMotion,
        visibleDays: _visibleDays,
        onDarkChanged: widget.onDarkChanged,
        onTransitionChanged: (value) => setState(() => _transition = value),
        onHeaderStyleChanged: (value) => setState(() => _headerStyle = value),
        onDensityChanged: (value) => setState(() => _density = value),
        onPaletteChanged: (value) => setState(() => _palette = value),
        onCourseCardStyleChanged: (value) =>
            setState(() => _courseCardStyle = value),
        onDetailLayoutChanged: (value) => setState(() => _detailLayout = value),
        onDetailHeroChanged: (value) => setState(() => _detailHero = value),
        onDetailPlacementChanged: (value) =>
            setState(() => _detailPlacement = value),
        onWeekPlacementChanged: (value) =>
            setState(() => _weekPlacement = value),
        onGlassChanged: (value) => setState(() => _glass = value),
        onWeatherSceneChanged: (value) => setState(() => _weatherScene = value),
        onReduceMotionChanged: (value) => setState(() => _reduceMotion = value),
        onVisibleDaysChanged: (value) => setState(() => _visibleDays = value),
      ),
    );
  }

  Future<void> _openWeather() {
    setState(() {
      final current = _weather.current!;
      _weather = YsWeatherSnapshot(
        current: YsCurrentWeather(
          kind: current.kind,
          temperatureC: (current.temperatureC ?? 24) + 0.2,
          label: current.label,
        ),
        daily: _weather.daily,
        updatedAt: DateTime.now(),
      );
    });
    return showYsAdaptiveSheet<void>(
      context: context,
      title: '当前位置天气',
      icon: ysWeatherIcon(_weather.current!.kind),
      kind: YsSheetKind.custom,
      theme: _kitTheme,
      config: _sheets,
      builder: (context, placement) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _weather.daily.length,
        separatorBuilder: (context, index) => Divider(color: _kitTheme.border),
        itemBuilder: (context, index) {
          final item = _weather.daily[index];
          return ListTile(
            leading: YsWeatherGlyph(kind: item.kind, color: _kitTheme.accent),
            title: Text(item.date),
            subtitle: Text(item.label ?? ysWeatherLabel(item.kind)),
            trailing: Text('${item.lowC?.round()}° / ${item.highC?.round()}°'),
          );
        },
      ),
    );
  }

  Future<void> _openDay(DateTime date) {
    final plans = _plans[formatDateKey(date)] ?? const <YsDayPlan>[];
    return showYsAdaptiveSheet<void>(
      context: context,
      title: '${date.month} 月 ${date.day} 日计划',
      icon: Icons.task_alt,
      kind: YsSheetKind.dayPlanner,
      theme: _kitTheme,
      config: _sheets,
      builder: (context, placement) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (plans.isEmpty)
            const ListTile(
              leading: Icon(Icons.event_available_outlined),
              title: Text('当天还没有计划'),
            )
          else
            for (final plan in plans)
              CheckboxListTile(
                value: plan.done,
                onChanged: (_) => _notice(plan.text),
                title: Text(plan.text),
              ),
        ],
      ),
    );
  }

  void _removeCourse(YsDisplayCourse value) {
    Navigator.of(context, rootNavigator: true).maybePop();
    setState(
        () => _courses.removeWhere((course) => course.id == value.course.id));
    _notice('已从演示数据移除 ${value.course.name}');
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<YsCourse> _demoCourses() => const [
        YsCourse(
          id: 'design',
          name: '城市设计工作坊',
          teacher: '林老师',
          location: '建筑馆 A201',
          weekday: 1,
          startSection: 1,
          endSection: 3,
          startWeek: 1,
          endWeek: 16,
          materials: ['绘图本', '针管笔'],
          books: [
            YsCourseBook(
              id: 'urban-design-methods',
              title: '城市设计方法',
              author: '王建国',
            ),
          ],
          materialDetails: [
            YsCourseMaterial(
              id: 'tracing-paper',
              name: '硫酸纸',
              kind: YsCourseMaterialKind.document,
              quantity: 3,
            ),
          ],
          tasks: [
            YsCourseTask(
              id: 'design-review',
              title: '提交街区公共空间草图',
              priority: YsCourseTaskPriority.high,
            ),
          ],
          note: '本周进行街区公共空间方案汇报。',
        ),
        YsCourse(
          id: 'statistics',
          name: '城市数据分析',
          teacher: '周老师',
          location: '计算中心 402',
          weekday: 2,
          startSection: 3,
          endSection: 4,
          startWeek: 1,
          endWeek: 18,
          materials: ['电脑'],
          tasks: [
            YsCourseTask(
              id: 'statistics-lab',
              title: '完成回归分析练习',
            ),
          ],
        ),
        YsCourse(
          id: 'theory',
          name: '规划理论前沿',
          teacher: '陈老师',
          location: '学院楼 312',
          weekday: 3,
          startSection: 1,
          endSection: 2,
          startWeek: 1,
          endWeek: 16,
          parity: YsWeekParity.odd,
          note: '课前阅读指定论文。',
        ),
        YsCourse(
          id: 'gis',
          name: 'GIS 空间分析',
          teacher: '顾老师',
          location: '实验室 B106',
          weekday: 4,
          startSection: 5,
          endSection: 7,
          startWeek: 1,
          endWeek: 18,
          materials: ['电脑', '校园卡'],
        ),
        YsCourse(
          id: 'english',
          name: '学术英语',
          teacher: 'Miller',
          location: '外语楼 207',
          weekday: 5,
          startSection: 3,
          endSection: 4,
          startWeek: 1,
          endWeek: 16,
        ),
        YsCourse(
          id: 'field',
          name: '社区调研',
          teacher: '项目组',
          location: '海河沿线',
          weekday: 6,
          startSection: 5,
          endSection: 8,
          startWeek: 2,
          endWeek: 14,
          parity: YsWeekParity.even,
          custom: true,
          materials: ['相机', '访谈提纲'],
        ),
      ];

  YsWeatherSnapshot _demoWeather(DateTime now) {
    final start = now.subtract(const Duration(days: 7));
    final kinds = [
      YsWeatherKind.clear,
      YsWeatherKind.cloudy,
      YsWeatherKind.rain,
      YsWeatherKind.heavyRain,
      YsWeatherKind.storm,
      YsWeatherKind.drizzle,
      YsWeatherKind.snow,
    ];
    return YsWeatherSnapshot(
      current: const YsCurrentWeather(
        kind: YsWeatherKind.cloudy,
        temperatureC: 26,
        label: '多云',
      ),
      daily: [
        for (var index = 0; index < 21; index++)
          YsDailyWeather(
            date: formatDateKey(start.add(Duration(days: index))),
            kind: kinds[index % kinds.length],
            lowC: 21 + index % 3,
            highC: 27 + index % 4,
            label: ysWeatherLabel(kinds[index % kinds.length]),
          ),
      ],
      updatedAt: DateTime.now(),
    );
  }
}

class _SettingsPanel extends StatefulWidget {
  const _SettingsPanel({
    required this.dark,
    required this.transition,
    required this.headerStyle,
    required this.density,
    required this.palette,
    required this.courseCardStyle,
    required this.detailLayout,
    required this.detailHero,
    required this.detailPlacement,
    required this.weekPlacement,
    required this.glass,
    required this.weatherScene,
    required this.reduceMotion,
    required this.visibleDays,
    required this.onDarkChanged,
    required this.onTransitionChanged,
    required this.onHeaderStyleChanged,
    required this.onDensityChanged,
    required this.onPaletteChanged,
    required this.onCourseCardStyleChanged,
    required this.onDetailLayoutChanged,
    required this.onDetailHeroChanged,
    required this.onDetailPlacementChanged,
    required this.onWeekPlacementChanged,
    required this.onGlassChanged,
    required this.onWeatherSceneChanged,
    required this.onReduceMotionChanged,
    required this.onVisibleDaysChanged,
  });

  final bool dark;
  final YsTransition transition;
  final YsHeaderStyle headerStyle;
  final YsScheduleDensity density;
  final YsPalette palette;
  final _CourseCardStyle courseCardStyle;
  final YsDetailLayout detailLayout;
  final YsDetailHero detailHero;
  final YsSheetPlacement detailPlacement;
  final YsSheetPlacement weekPlacement;
  final bool glass;
  final bool weatherScene;
  final bool reduceMotion;
  final int visibleDays;
  final ValueChanged<bool> onDarkChanged;
  final ValueChanged<YsTransition> onTransitionChanged;
  final ValueChanged<YsHeaderStyle> onHeaderStyleChanged;
  final ValueChanged<YsScheduleDensity> onDensityChanged;
  final ValueChanged<YsPalette> onPaletteChanged;
  final ValueChanged<_CourseCardStyle> onCourseCardStyleChanged;
  final ValueChanged<YsDetailLayout> onDetailLayoutChanged;
  final ValueChanged<YsDetailHero> onDetailHeroChanged;
  final ValueChanged<YsSheetPlacement> onDetailPlacementChanged;
  final ValueChanged<YsSheetPlacement> onWeekPlacementChanged;
  final ValueChanged<bool> onGlassChanged;
  final ValueChanged<bool> onWeatherSceneChanged;
  final ValueChanged<bool> onReduceMotionChanged;
  final ValueChanged<int> onVisibleDaysChanged;

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  late bool dark = widget.dark;
  late YsTransition transition = widget.transition;
  late YsHeaderStyle headerStyle = widget.headerStyle;
  late YsScheduleDensity density = widget.density;
  late YsPalette palette = widget.palette;
  late _CourseCardStyle courseCardStyle = widget.courseCardStyle;
  late YsDetailLayout detailLayout = widget.detailLayout;
  late YsDetailHero detailHero = widget.detailHero;
  late YsSheetPlacement detailPlacement = widget.detailPlacement;
  late YsSheetPlacement weekPlacement = widget.weekPlacement;
  late bool glass = widget.glass;
  late bool weatherScene = widget.weatherScene;
  late bool reduceMotion = widget.reduceMotion;
  late int visibleDays = widget.visibleDays;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _section('课表'),
        _dropdown(
          '换周动画',
          transition,
          YsTransition.values,
          _transitionLabel,
          (value) {
            setState(() => transition = value);
            widget.onTransitionChanged(value);
          },
        ),
        _dropdown(
          '周 Header',
          headerStyle,
          YsHeaderStyle.values
              .where((value) => value != YsHeaderStyle.none)
              .toList(),
          _headerLabel,
          (value) {
            setState(() => headerStyle = value);
            widget.onHeaderStyleChanged(value);
          },
        ),
        _dropdown('信息密度', density, YsScheduleDensity.values, _densityLabel,
            (value) {
          setState(() => density = value);
          widget.onDensityChanged(value);
        }),
        _dropdown('课程配色', palette, YsPalette.values, _paletteLabel, (value) {
          setState(() => palette = value);
          widget.onPaletteChanged(value);
        }),
        _dropdown('课程卡表现', courseCardStyle, _CourseCardStyle.values,
            _courseCardStyleLabel, (value) {
          setState(() => courseCardStyle = value);
          widget.onCourseCardStyleChanged(value);
        }),
        _dropdown('显示星期', visibleDays, const [5, 6, 7], (value) => '$value 天',
            (value) {
          setState(() => visibleDays = value);
          widget.onVisibleDaysChanged(value);
        }),
        _section('课程详情'),
        _dropdown('默认档位', detailLayout, YsDetailLayout.values, _detailLabel,
            (value) {
          setState(() => detailLayout = value);
          widget.onDetailLayoutChanged(value);
        }),
        _dropdown('头图样式', detailHero, YsDetailHero.values, _heroLabel, (value) {
          setState(() => detailHero = value);
          widget.onDetailHeroChanged(value);
        }),
        _dropdown(
            '默认位置', detailPlacement, YsSheetPlacement.values, _placementLabel,
            (value) {
          setState(() => detailPlacement = value);
          widget.onDetailPlacementChanged(value);
        }),
        _dropdown(
            '周选择器位置', weekPlacement, YsSheetPlacement.values, _placementLabel,
            (value) {
          setState(() => weekPlacement = value);
          widget.onWeekPlacementChanged(value);
        }),
        _section('外观与动态'),
        SwitchListTile(
          value: dark,
          onChanged: (value) {
            setState(() => dark = value);
            widget.onDarkChanged(value);
          },
          title: const Text('深色主题'),
          secondary: const Icon(Icons.dark_mode_outlined),
        ),
        SwitchListTile(
          value: weatherScene,
          onChanged: (value) {
            setState(() => weatherScene = value);
            widget.onWeatherSceneChanged(value);
          },
          title: const Text('天气场景'),
          secondary: const Icon(Icons.cloud_outlined),
        ),
        SwitchListTile(
          value: glass,
          onChanged: (value) {
            setState(() => glass = value);
            widget.onGlassChanged(value);
          },
          title: const Text('弹窗毛玻璃'),
          secondary: const Icon(Icons.blur_on_outlined),
        ),
        SwitchListTile(
          value: reduceMotion,
          onChanged: (value) {
            setState(() => reduceMotion = value);
            widget.onReduceMotionChanged(value);
          },
          title: const Text('减少动态效果'),
          secondary: const Icon(Icons.motion_photos_off_outlined),
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      );

  Widget _dropdown<T>(
    String label,
    T value,
    List<T> values,
    String Function(T value) valueLabel,
    ValueChanged<T> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(valueLabel(item))),
        ],
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

  String _transitionLabel(YsTransition value) => switch (value) {
        YsTransition.wave => '波浪覆盖',
        YsTransition.slide => '平滑滑动',
        YsTransition.fade => '交叉淡入',
        YsTransition.cube => '立方体',
        YsTransition.drop => '轻落',
        YsTransition.zoom => '缩放',
        YsTransition.none => '无动画',
      };

  String _headerLabel(YsHeaderStyle value) => switch (value) {
        YsHeaderStyle.compact => '精简',
        YsHeaderStyle.standard => '标准',
        YsHeaderStyle.expanded => '展开',
        YsHeaderStyle.none => '隐藏',
      };

  String _densityLabel(YsScheduleDensity value) => switch (value) {
        YsScheduleDensity.minimal => '精简',
        YsScheduleDensity.normal => '适中',
        YsScheduleDensity.rich => '全面',
      };

  String _paletteLabel(YsPalette value) => switch (value) {
        YsPalette.classic => '经典',
        YsPalette.macaron => '马卡龙',
        YsPalette.morandi => '莫兰迪',
        YsPalette.cyber => '赛博',
        YsPalette.forest => '森林',
        YsPalette.sunset => '日落',
      };

  String _courseCardStyleLabel(_CourseCardStyle value) => switch (value) {
        _CourseCardStyle.weather => '实时天气',
        _CourseCardStyle.none => '无',
        _CourseCardStyle.shimmer => '微光',
        _CourseCardStyle.glow => '辉光',
        _CourseCardStyle.aurora => '极光',
        _CourseCardStyle.breathe => '呼吸',
      };

  String _detailLabel(YsDetailLayout value) => switch (value) {
        YsDetailLayout.compact => '精简',
        YsDetailLayout.standard => '适中',
        YsDetailLayout.full => '全面',
      };

  String _heroLabel(YsDetailHero value) => switch (value) {
        YsDetailHero.courseColor => '课程色',
        YsDetailHero.weather => '天气联动',
        YsDetailHero.plain => '极简',
      };

  String _placementLabel(YsSheetPlacement value) => switch (value) {
        YsSheetPlacement.bottom => '底部抽屉',
        YsSheetPlacement.center => '居中对话框',
        YsSheetPlacement.right => '右侧面板',
      };
}
