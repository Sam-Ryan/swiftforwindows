#include "ObjCClasses.h"
#include <stdio.h>

@implementation HasHiddenIvars
@synthesize x;
@synthesize y;
@synthesize z;
@synthesize t;
@end

@implementation NilError
+ (BOOL) throwIt: (NSError**) error {
  return 0;
}
@end

@implementation Container
- (id)initWithObject:(id)anObject {
  if ((self = [super init]) != nil) {
    self.object = anObject;
  }
  return self;
}

- (void)processObjectWithBlock:(void (^)(id))block {
  block(self.object);
}

- (void)updateObjectWithBlock:(id (^)())block {
  self.object = block();
}

@synthesize object;

- (id)initWithCat1:(id)anObject {
  return [self initWithObject:anObject];
}

- (id)getCat1 {
  return self.object;
}

- (void)setCat1:(id)obj {
  self.object = obj;
}

- (id)cat1Property {
  return self.object;
}

- (void)setCat1Property:(id)prop {
  self.object = prop;
}

@end

@implementation SubContainer
@end

@implementation NestedContainer
@end

@implementation StringContainer
@end

@implementation CopyingContainer
@end

@implementation Animal
- (NSString *)noise {
  return @"eep";
}
@end

@implementation Dog
- (NSString *)noise {
  return @"woof";
}
@end

@implementation AnimalContainer
@end

#if __has_feature(objc_class_property)
static int _value = 0;
@implementation ClassWithClassProperty
+ (int)value {
  return _value;
}
+ (void)setValue:(int)newValue {
  _value = newValue;
}
+ (void)reset {
  _value = 0;
}
@end

@implementation ObjCSubclassWithClassProperty
+ (BOOL)optionalClassProp {
  return YES;
}
@end

@implementation PropertyNamingConflict
- (id)prop { return self; }
+ (id)prop { return nil; }
@end

#endif
