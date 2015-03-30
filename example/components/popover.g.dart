// GENERATED CODE - DO NOT MODIFY BY HAND
// 2015-03-30T05:04:00.987Z

part of uix_dbmon.components.popover;

// **************************************************************************
// Generator: UixGenerator
// Target: class Popover
// **************************************************************************

Popover createPopover([String data, List<VNode> children, Component parent]) {
  return new Popover()
    ..parent = parent
    ..data = data
    ..children = children;
}
VNode vPopover({String data, Object key, String type, Map<String, String> attrs,
    Map<String, String> style, List<String> classes,
    List<VNode> children}) => new VNode.component(createPopover,
    flags: VNode.componentFlag,
    key: key,
    data: data,
    type: type,
    attrs: attrs,
    style: style,
    classes: classes,
    children: children);
