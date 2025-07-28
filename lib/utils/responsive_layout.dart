import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    
    // If width is more than 1100, we consider it a desktop
    if (size.width >= 1100) {
      return desktop ?? tablet ?? mobile;
    }
    
    // If width is more than 650, we consider it a tablet
    else if (size.width >= 650) {
      return tablet ?? mobile;
    }
    
    // Otherwise, we consider it a mobile
    else {
      return mobile;
    }
  }
}

class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;
  
  const ResponsiveGridView({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount;
        
        if (constraints.maxWidth < 650) {
          crossAxisCount = 1; // Mobile
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2; // Tablet
        } else {
          crossAxisCount = 3; // Desktop
        }
        
        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 3 / 2,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints, ScreenSize screenSize) builder;
  
  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        ScreenSize screenSize;
        
        if (constraints.maxWidth < 650) {
          screenSize = ScreenSize.mobile;
        } else if (constraints.maxWidth < 1100) {
          screenSize = ScreenSize.tablet;
        } else {
          screenSize = ScreenSize.desktop;
        }
        
        return builder(context, constraints, screenSize);
      },
    );
  }
}

enum ScreenSize {
  mobile,
  tablet,
  desktop,
}