import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';

import 'choicechip.dart';

class TextFilterChoicechip extends StatelessWidget {
  const TextFilterChoicechip({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(200, 76)),
      direction: PopoverDirection.bottomWithCenterAligned,
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: TextFilterEditor(filterId: filterId),
        );
      },
      child: SingleFilterBlocSelector<TextFilter>(
        filterId: filterId,
        builder: (context, filter, field) {
          return ChoiceChipButton(
            fieldInfo: field,
            filterDesc: filter.getContentDescription(field),
          );
        },
      ),
    );
  }
}

class TextFilterEditor extends StatefulWidget {
  const TextFilterEditor({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  State<TextFilterEditor> createState() => _TextFilterEditorState();
}

class _TextFilterEditorState extends State<TextFilterEditor> {
  final popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleFilterBlocSelector<TextFilter>(
      filterId: widget.filterId,
      builder: (context, filter, field) {
        final List<Widget> children = [
          _buildFilterPanel(filter, field),
        ];

        if (filter.condition != TextFilterConditionPB.TextIsEmpty &&
            filter.condition != TextFilterConditionPB.TextIsNotEmpty) {
          children.add(const VSpace(4));
          children.add(_buildFilterTextField(filter, field));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: IntrinsicHeight(child: Column(children: children)),
        );
      },
    );
  }

  Widget _buildFilterPanel(TextFilter filter, FieldInfo field) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: FlowyText(
              field.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(4),
          Expanded(
            child: TextFilterConditionList(
              filter: filter,
              popoverMutex: popoverMutex,
              onCondition: (condition) {
                final newFilter = filter.copyWith(condition: condition);
                context
                    .read<FilterEditorBloc>()
                    .add(FilterEditorEvent.updateFilter(newFilter));
              },
            ),
          ),
          const HSpace(4),
          DisclosureButton(
            popoverMutex: popoverMutex,
            onAction: (action) {
              switch (action) {
                case FilterDisclosureAction.delete:
                  context
                      .read<FilterEditorBloc>()
                      .add(FilterEditorEvent.deleteFilter(filter.filterId));
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTextField(TextFilter filter, FieldInfo field) {
    return FlowyTextField(
      text: filter.content,
      hintText: LocaleKeys.grid_settings_typeAValue.tr(),
      debounceDuration: const Duration(milliseconds: 300),
      autoFocus: false,
      onChanged: (text) {
        final newFilter = filter.copyWith(content: text);
        context
            .read<FilterEditorBloc>()
            .add(FilterEditorEvent.updateFilter(newFilter));
      },
    );
  }
}

class TextFilterConditionList extends StatelessWidget {
  const TextFilterConditionList({
    super.key,
    required this.filter,
    required this.popoverMutex,
    required this.onCondition,
  });

  final TextFilter filter;
  final PopoverMutex popoverMutex;
  final void Function(TextFilterConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: TextFilterConditionPB.values
          .map(
            (action) => ConditionWrapper(
              action,
              filter.condition == action,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: filter.condition.filterName,
          onTap: () => controller.show(),
        );
      },
      onSelected: (action, controller) async {
        onCondition(action.inner);
        controller.close();
      },
    );
  }
}

class ConditionWrapper extends ActionCell {
  ConditionWrapper(this.inner, this.isSelected);

  final TextFilterConditionPB inner;
  final bool isSelected;

  @override
  Widget? rightIcon(Color iconColor) {
    if (isSelected) {
      return const FlowySvg(FlowySvgs.check_s);
    } else {
      return null;
    }
  }

  @override
  String get name => inner.filterName;
}

extension TextFilterConditionPBExtension on TextFilterConditionPB {
  String get filterName {
    switch (this) {
      case TextFilterConditionPB.TextContains:
        return LocaleKeys.grid_textFilter_contains.tr();
      case TextFilterConditionPB.TextDoesNotContain:
        return LocaleKeys.grid_textFilter_doesNotContain.tr();
      case TextFilterConditionPB.TextEndsWith:
        return LocaleKeys.grid_textFilter_endsWith.tr();
      case TextFilterConditionPB.TextIs:
        return LocaleKeys.grid_textFilter_is.tr();
      case TextFilterConditionPB.TextIsNot:
        return LocaleKeys.grid_textFilter_isNot.tr();
      case TextFilterConditionPB.TextStartsWith:
        return LocaleKeys.grid_textFilter_startWith.tr();
      case TextFilterConditionPB.TextIsEmpty:
        return LocaleKeys.grid_textFilter_isEmpty.tr();
      case TextFilterConditionPB.TextIsNotEmpty:
        return LocaleKeys.grid_textFilter_isNotEmpty.tr();
      default:
        return "";
    }
  }

  String get choicechipPrefix {
    switch (this) {
      case TextFilterConditionPB.TextDoesNotContain:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isNot.tr();
      case TextFilterConditionPB.TextEndsWith:
        return LocaleKeys.grid_textFilter_choicechipPrefix_endWith.tr();
      case TextFilterConditionPB.TextIsNot:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isNot.tr();
      case TextFilterConditionPB.TextStartsWith:
        return LocaleKeys.grid_textFilter_choicechipPrefix_startWith.tr();
      case TextFilterConditionPB.TextIsEmpty:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isEmpty.tr();
      case TextFilterConditionPB.TextIsNotEmpty:
        return LocaleKeys.grid_textFilter_choicechipPrefix_isNotEmpty.tr();
      default:
        return "";
    }
  }
}