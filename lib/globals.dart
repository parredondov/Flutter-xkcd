import 'package:flutter/material.dart';
import 'package:xkcd/main.dart';

import 'models/comic.dart';

double toolbarIconSize = 24;
int current = 0;
int viewed = 0;
bool firstLoad = true;
BuildContext ctx;
Comic comic;
List<int> comicList = new List();
bool iconFlag = false;