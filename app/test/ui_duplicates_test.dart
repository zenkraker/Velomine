import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// The duplicated UI patterns the shared-widget rule keeps down, and the most of each one the code may hold.
/// A count may not rise (use the shared widget) and may not fall without lowering its number here.
const _budget = <String, int>{
  'private widget class': 93,
  'Card(': 3,
  'TextField( or TextFormField(': 1,
  'showSnackBar': 5,
  'SegmentedButton(': 1,
  'TextStyle(': 0,
  'Color(0x': 0,
  'EdgeInsets.all(number)': 0,
  'SizedBox(height: number)': 1,
  'SizedBox(width: number)': 0,
  'spacing: number': 0,
};

/// The classes a hand-rolled widget extends; the State halves of a stateful widget are not counted twice.
const _widgetBases = {
  'StatelessWidget',
  'StatefulWidget',
  'ConsumerWidget',
  'ConsumerStatefulWidget',
};

/// Counts the patterns on the syntax tree, so comments, strings and names like `AppTextField(` never match.
class _Counter extends RecursiveAstVisitor<void> {
  final counts = {for (final name in _budget.keys) name: 0};

  void _hit(String name) => counts[name] = counts[name]! + 1;

  static bool _number(Expression? e) =>
      e is IntegerLiteral || e is DoubleLiteral;

  static Expression? _named(ArgumentList args, String name) {
    for (final a in args.arguments) {
      if (a is NamedArgument && a.name.lexeme == name) {
        return a.argumentExpression;
      }
    }
    return null;
  }

  /// A call without `new` or `const` parses as a method call, so `Card(...)` and `EdgeInsets.all(...)` both
  /// arrive here as (type, constructor, arguments).
  void _call(String? type, String name, ArgumentList args) {
    final target = type ?? name;
    final first = args.arguments.firstOrNull?.argumentExpression;
    switch (target) {
      case 'Card':
        _hit('Card(');
      case 'TextField' || 'TextFormField':
        _hit('TextField( or TextFormField(');
      case 'SegmentedButton':
        _hit('SegmentedButton(');
      case 'TextStyle':
        _hit('TextStyle(');
      case 'Color'
          when first is IntegerLiteral && first.literal.lexeme.startsWith('0x'):
        _hit('Color(0x');
      case 'EdgeInsets' when type != null && name == 'all' && _number(first):
        _hit('EdgeInsets.all(number)');
      case 'SizedBox':
        if (_number(_named(args, 'height'))) _hit('SizedBox(height: number)');
        if (_number(_named(args, 'width'))) _hit('SizedBox(width: number)');
    }
    if (_number(_named(args, 'spacing'))) _hit('spacing: number');
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    if (node.methodName.name == 'showSnackBar') _hit('showSnackBar');
    _call(
      target is SimpleIdentifier ? target.name : null,
      node.methodName.name,
      node.argumentList,
    );
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final c = node.constructorName;
    _call(c.type.name.lexeme, c.name?.name ?? '', node.argumentList);
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    final parent = node.extendsClause?.superclass.name.lexeme;
    if (node.namePart.typeName.lexeme.startsWith('_') &&
        _widgetBases.contains(parent)) {
      _hit('private widget class');
    }
    super.visitClassDeclaration(node);
  }
}

void main() {
  test('UiDuplicates_ShouldMatchTheBudget_WhenCodeChanges', () {
    final counter = _Counter();
    for (final dir in ['lib/features', 'lib/core']) {
      for (final file in Directory(
        dir,
      ).listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        // lib/core/theme.dart defines the tokens, so its colours and text styles are the source, not copies.
        if (file.path.endsWith('lib/core/theme.dart')) continue;
        parseString(
          content: file.readAsStringSync(),
          path: file.path,
          throwIfDiagnostics: false,
        ).unit.accept(counter);
      }
    }
    final off = [
      for (final e in counter.counts.entries)
        if (e.value != _budget[e.key]!)
          '${e.key}: budget ${_budget[e.key]}, found ${e.value}'
              '${e.value > _budget[e.key]! ? ' (use the shared widget)' : ' (lower the budget)'}',
    ];
    expect(off, isEmpty, reason: 'The counts and the budget must agree.');
  });
}
