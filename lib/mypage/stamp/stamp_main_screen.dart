import 'package:flutter/material.dart';
import 'repository/stamp_repository.dart';
import 'utils/stamp_data_processor.dart'; // 신규 import
import 'widgets/sub_filter_chips.dart';
import 'widgets/sorting_bar.dart';
import 'widgets/menu_select_modal.dart';
import 'widgets/stamp_board_modal.dart';
import 'widgets/stamp_course_card.dart'; // 신규 import
import '../../../../road/widgets/region_select_page.dart';

class StampMainScreen extends StatefulWidget {
  const StampMainScreen({super.key});

  @override
  State<StampMainScreen> createState() => _StampMainScreenState();
}

class _StampMainScreenState extends State<StampMainScreen> {
  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);
  static const Color subTextColor = Color(0xFF7A6B63);

  String _selectedTab = '지역별';
  String _selectedFilter = '전체';
  String _selectedSort = '최신순';

  List<String> _dbMenuFilters = ['전체'];

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndRegions();
  }

  void _loadCategoriesAndRegions() async {
    final categories = await StampRepository.getCategoryNames();
    if (mounted) {
      setState(() {
        _dbMenuFilters = categories;
      });
    }
  }

  void _openMenuSelectModal() async {
    final selected = await MenuSelectModal.show(
      context,
      menuOptions: _dbMenuFilters,
      selectedFilter: _selectedFilter,
    );

    if (selected != null) {
      setState(() => _selectedFilter = selected);
    }
  }

  Future<void> _openRegionSelectModal() async {
    final selectedRegion = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegionSelectPage(),
      ),
    );

    if (selectedRegion != null && selectedRegion is String) {
      setState(() {
        _selectedFilter = selectedRegion;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: creamyIvory,
      appBar: AppBar(
        title: const Text(
          '스탬프',
          style: TextStyle(color: deepChocolate, fontWeight: FontWeight.bold),
        ),
        backgroundColor: creamyIvory,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: deepChocolate),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      _buildTabButton('지역별'),
                      _buildTabButton('메뉴별'),
                    ],
                  ),
                  SortingBar(
                    selectedSort: _selectedSort,
                    onSortChanged: (sort) =>
                        setState(() => _selectedSort = sort),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            SubFilterChips(
              selectedTab: _selectedTab,
              selectedFilter: _selectedFilter,
              menuFilters: _dbMenuFilters,
              onFilterSelected: (filter) =>
                  setState(() => _selectedFilter = filter),
              onMorePressed: _selectedTab == '지역별'
                  ? _openRegionSelectModal
                  : _openMenuSelectModal,
            ),
            const SizedBox(height: 8),

            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: StampRepository.getRoadWithMyStampStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: deepChocolate));
                  }

                  final rawList = snapshot.data ?? [];
                  // 🌟 외부 Util로 로직 위임
                  final processedList = StampDataProcessor.process(
                    rawList: rawList,
                    selectedTab: _selectedTab,
                    selectedFilter: _selectedFilter,
                    selectedSort: _selectedSort,
                  );

                  if (processedList.isEmpty) {
                    return const Center(
                      child: Text(
                        '조건에 해당하는 스탬프 로드가 없습니다.',
                        style: TextStyle(color: subTextColor),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: processedList.length,
                    itemBuilder: (context, index) {
                      final road = processedList[index];
                      // 🌟 외부 Widget으로 UI 위임
                      return StampCourseCard(
                        roadData: road,
                        onTap: () => StampBoardModal.show(context, road),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label) {
    final bool isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
          _selectedFilter = '전체';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? pointCoralRed : subTextColor,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 3,
              width: 36,
              decoration: BoxDecoration(
                color: isSelected ? pointCoralRed : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}