#import <Foundation/Foundation.h>

// Forward declare the class to avoid circular imports
@class TTKSettingsBaseCellPlugin;

@interface AWEBaseListSectionViewModel: NSObject
@property(nonatomic, copy, readwrite) NSArray *modelsArray;
- (void)insertModel:(id)model atIndex:(NSInteger)index animated:(BOOL)animated;
@end

@interface AWESettingsNormalSectionViewModel: AWEBaseListSectionViewModel
@property(nonatomic, weak, readwrite) id context;
@property(nonatomic, copy, readwrite) NSString *sectionIdentifier;
@end
