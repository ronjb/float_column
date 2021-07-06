import 'package:flutter/material.dart';

import 'package:float_column/float_column.dart';

class InlineFloats extends StatelessWidget {
  const InlineFloats({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 18, color: Colors.black, height: 1.5),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FloatColumn(
            children: [
              WrappableText(
                text: _process(_str),
                margin: const EdgeInsetsDirectional.only(start: 60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextSpan _process(String str) {
  return TextSpan(
    children: str.split(' *').expand(
      (str) {
        final s = str.split('* ');
        if (s.length == 2) {
          final cit = s.first;
          return [
            TextSpan(text: ' (${cit.substring(cit.length - 1)})'),
            WidgetSpan(
              child: Floatable(float: FCFloat.left, clear: FCClear.both, child: Text(cit)),
            ),
            TextSpan(text: ' ${s.last}'),
          ];
        } else {
          return [TextSpan(text: str)];
        }
      },
    ).toList(),
  );
}

// cspell: disable
const _str = '''
Lorem ipsum dolor sit amet, consectetur *132a* adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Id aliquet risus feugiat in ante metus dictum at. Duis tristique sollicitudin nibh sit amet commodo. Ut aliquam *133b* purus sit amet luctus. Ullamcorper velit sed ullamcorper morbi tincidunt. Amet commodo nulla facilisi nullam vehicula ipsum. Faucibus interdum posuere lorem ipsum dolor sit amet consectetur. Nunc congue nisi vitae suscipit tellus. Dis parturient montes nascetur ridiculus. Sit amet venenatis *134c* urna cursus eget nunc scelerisque viverra mauris. Scelerisque mauris pellentesque pulvinar pellentesque habitant morbi tristique. Tellus integer feugiat scelerisque varius morbi enim. Ut consequat *135d* semper viverra nam libero justo. Egestas integer eget aliquet nibh praesent tristique magna sit. Scelerisque fermentum dui faucibus in ornare quam viverra. Amet massa vitae tortor condimentum *136e* lacinia quis vel eros. Placerat vestibulum lectus mauris ultrices eros in. Facilisi cras fermentum odio eu feugiat pretium. Purus sit amet luctus venenatis lectus. Molestie nunc non blandit *137f* massa enim nec dui nunc.

Adipiscing vitae proin sagittis nisl rhoncus mattis rhoncus urna neque. Tellus orci ac auctor augue mauris augue neque gravida. Nisi lacus sed *138g* viverra tellus in. Dui accumsan sit amet nulla facilisi morbi tempus iaculis urna. Viverra suspendisse potenti nullam ac tortor vitae purus. Pretium vulputate sapien nec sagittis. Purus viverra accumsan in nisl nisi scelerisque eu. Scelerisque fermentum dui faucibus in ornare. Tellus *139h* pellentesque eu tincidunt tortor aliquam nulla. Lacinia quis vel eros donec ac odio tempor orci. Eget lorem dolor sed viverra ipsum nunc. Placerat orci nulla pellentesque dignissim enim sit amet venenatis urna. Arcu odio ut sem nulla pharetra diam sit. Sagittis nisl rhoncus mattis *140i* rhoncus urna neque viverra. Tortor aliquam nulla facilisi cras fermentum odio eu feugiat pretium. Amet porttitor eget dolor morbi non arcu risus quis varius.
''';

/*
Proin fermentum leo vel orci porta. Pellentesque nec nam aliquam sem et tortor. Non quam lacus suspendisse faucibus interdum. In ornare quam viverra orci sagittis eu volutpat. Ultrices gravida dictum fusce ut placerat. Mattis aliquam faucibus purus in massa tempor nec. Et molestie ac feugiat sed lectus. Morbi tristique senectus et netus et malesuada fames ac turpis. Nec dui nunc mattis enim ut tellus elementum. Id volutpat lacus laoreet non curabitur. Elementum nibh tellus molestie nunc non. Vestibulum rhoncus est pellentesque elit.

Lorem dolor sed viverra ipsum nunc aliquet bibendum enim facilisis. Sagittis purus sit amet volutpat consequat mauris. Dolor sit amet consectetur adipiscing elit ut. Id leo in vitae turpis massa sed elementum. Habitant morbi tristique senectus et netus et. Sollicitudin nibh sit amet commodo nulla facilisi. Quis imperdiet massa tincidunt nunc. Eleifend donec pretium vulputate sapien nec sagittis aliquam malesuada. Sed vulputate mi sit amet mauris commodo quis imperdiet massa. Vitae aliquet nec ullamcorper sit amet risus nullam eget felis. Facilisi nullam vehicula ipsum a arcu cursus vitae. Facilisis mauris sit amet massa vitae tortor condimentum. Tortor at auctor urna nunc id cursus metus aliquam. Erat imperdiet sed euismod nisi. Morbi tristique senectus et netus. Lacus luctus accumsan tortor posuere ac ut consequat semper viverra.

At tellus at urna condimentum mattis. Nisl condimentum id venenatis a condimentum vitae. Tellus in metus vulputate eu scelerisque felis imperdiet. Nec tincidunt praesent semper feugiat. Eu sem integer vitae justo eget. Augue interdum velit euismod in. Eget mauris pharetra et ultrices neque ornare. Lectus arcu bibendum at varius vel pharetra vel turpis. Magna sit amet purus gravida quis. Ut enim blandit volutpat maecenas volutpat blandit. Arcu felis bibendum ut tristique. Habitant morbi tristique senectus et netus et malesuada fames ac.
*/