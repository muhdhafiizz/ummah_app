import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ramadhan_companion_app/provider/doa_zikir_provider.dart';
import 'package:ramadhan_companion_app/widgets/app_colors.dart';
import 'package:ramadhan_companion_app/widgets/shimmer_loading.dart';

class DetailsDoaView extends StatelessWidget {
  const DetailsDoaView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = DoaProvider();
        provider.getAllDoa();
        return provider;
      },
      builder: (context, _) {
        final provider = context.watch<DoaProvider>();

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                const SizedBox(height: 30),
                _buildFilterChips(context, provider),
                const SizedBox(height: 15),
                Expanded(child: _doaContent(context, provider)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Doa',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    DoaProvider provider, {
    bool isFirst = false,
  }) {
    return Container(
      margin: EdgeInsets.only(left: isFirst ? 8 : 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: provider.sources.asMap().entries.map((entry) {
            final index = entry.key;
            final source = entry.value;
            final isSelected = provider.selectedSource == source;
            final displayText = source == "all"
                ? "All"
                : source[0].toUpperCase() + source.substring(1);

            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 8 : 0, right: 8),
              child: GestureDetector(
                onTap: () => provider.selectSource(source),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.violet.withOpacity(0.1),
                    border: isSelected
                        ? Border.all(
                            color: AppColors.violet.withOpacity(1),
                            width: 1.5,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: AppColors.violet.withOpacity(1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(2, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: ShimmerLoadingWidget(height: 200, width: double.infinity),
        );
      }),
    );
  }

  Widget _doaContent(BuildContext context, DoaProvider provider) {
    if (provider.isLoading) {
      return Center(child: _buildShimmerLoading());
    }

    if (provider.errorMessage != null) {
      return Center(child: Text(provider.errorMessage!));
    }

    if (provider.doaList.isEmpty) {
      return const Center(child: Text("No doa found."));
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: provider.doaList.length,
        itemBuilder: (context, index) {
          final doa = provider.doaList[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doa.judul,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doa.arab,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 20,
                      height: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(doa.indo, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    "Source: ${doa.source}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
