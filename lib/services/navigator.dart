import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

push_next_page(context, Widget nextPage) {
  Navigator.of(context).push(MaterialPageRoute(builder: (context) => nextPage));
}
