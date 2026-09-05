#import <Cocoa/Cocoa.h>
#include <string.h>
#include "native_protocol.h"

@interface BlazeXSpikeDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource>
@property NSWindow *window;
@property BxNativeBatch batch;
@end

@implementation BlazeXSpikeDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  (void)notification;
  self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 420, 320)
    styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
    backing:NSBackingStoreBuffered defer:NO];
  NSStackView *stack = [NSStackView stackViewWithViews:@[]];
  stack.orientation = NSUserInterfaceLayoutOrientationVertical;
  for (size_t index = 0; index < self.batch.node_count; ++index) {
    BxNativeNode node = self.batch.nodes[index];
    NSString *label = [NSString stringWithUTF8String:node.name[0] ? node.name : node.text];
    NSView *view = nil;
    if (strcmp(node.kind, "text") == 0)
      view = [NSTextField labelWithString:label];
    else if (strcmp(node.kind, "action") == 0)
      view = [NSButton buttonWithTitle:label target:nil action:nil];
    else if (strcmp(node.kind, "field") == 0)
      view = [[NSTextField alloc] initWithFrame:NSZeroRect];
    else if (strcmp(node.kind, "selection") == 0 && strcmp(node.role, "checkbox") == 0)
      view = [NSButton checkboxWithTitle:label target:nil action:nil];
    else if (strcmp(node.kind, "collection") == 0) {
      NSTableView *table = [[NSTableView alloc] initWithFrame:NSZeroRect];
      table.dataSource = self;
      view = table;
    }
    if (view != nil) [stack addArrangedSubview:view];
  }
  self.window.contentView = stack;
  [self.window makeKeyAndOrderFront:nil];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView { (void)tableView; return 2; }
- (void)deferredFileChoice { NSOpenPanel *panel = [NSOpenPanel openPanel]; (void)panel; }
@end

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    if (argc != 2) return 2;
    BxNativeBatch batch;
    char error[BX_MAX_ERROR] = {0};
    if (!bx_read_batch(argv[1], &batch, error)) return 3;
    NSApplication *application = [NSApplication sharedApplication];
    BlazeXSpikeDelegate *delegate = [BlazeXSpikeDelegate new];
    delegate.batch = batch;
    application.delegate = delegate;
    [application run];
  }
  return 0;
}
