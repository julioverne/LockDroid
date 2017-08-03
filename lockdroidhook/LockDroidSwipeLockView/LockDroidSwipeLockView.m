#import "LockDroidSwipeLockView.h"
#import "LockDroidSwipeLockNodeView.h"
@interface LockDroidSwipeLockView()
@property (nonatomic, strong) NSMutableArray *nodeArray;
@property (nonatomic, strong) NSMutableArray *selectedNodeArray;
@property (nonatomic, strong) CAShapeLayer *polygonalLineLayer;
@property (nonatomic, strong) UIBezierPath *polygonalLinePath;
@property (nonatomic, strong) NSMutableArray *pointArray;

@property (nonatomic) LockDroidSwipeLockViewState viewState;
@end

@implementation LockDroidSwipeLockView
-(id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self.layer addSublayer:self.polygonalLineLayer];
        
        _nodeArray = [NSMutableArray arrayWithCapacity:9];
        for (int i = 0; i < 9; ++i) {
            LockDroidSwipeLockNodeView *nodeView = [LockDroidSwipeLockNodeView new];
            [_nodeArray addObject:nodeView];
            nodeView.tag = i;
            [self addSubview:nodeView];
        }
        _selectedNodeArray = [NSMutableArray arrayWithCapacity:9];
        _pointArray = [NSMutableArray array];
        
        UIPanGestureRecognizer *panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:panRec];
        self.viewState = LockDroidSwipeLockNodeViewStatusNormal;
        [self cleanNodes];
        
    }
    return self;
}

-(void)pan:(UIPanGestureRecognizer *)rec
{
	@autoreleasepool {
    if  (rec.state == UIGestureRecognizerStateBegan){
        self.viewState = LockDroidSwipeLockNodeViewStatusNormal;
    }
    
    CGPoint touchPoint = [rec locationInView:self];
    NSInteger index = [self indexForNodeAtPoint:touchPoint];
    if (index >= 0) {
        LockDroidSwipeLockNodeView *node = self.nodeArray[index];
        
        if (![self addSelectedNode:node]) {
            [self moveLineWithFingerPosition:touchPoint];

        }
    }else{
        [self moveLineWithFingerPosition:touchPoint];
        
    }
    
    if (rec.state == UIGestureRecognizerStateEnded) {
        
        [self removeLastFingerPosition];
        if([self.delegate respondsToSelector:@selector(swipeView:didEndSwipeWithPassword:)]){
            NSMutableString *password = [NSMutableString new];
            for(LockDroidSwipeLockNodeView *nodeView in self.selectedNodeArray){
                NSString *index = [@(nodeView.tag) stringValue];
                [password appendString:index];
            }
            self.viewState = [self.delegate swipeView:self didEndSwipeWithPassword:password];
            
        }
        else{
            self.viewState = LockDroidSwipeLockViewStateSelected;
        }
    }
    }
}

-(BOOL)addSelectedNode:(LockDroidSwipeLockNodeView *)nodeView
{
	@autoreleasepool {
    if (![self.selectedNodeArray containsObject:nodeView]) {
        nodeView.nodeViewStatus = LockDroidSwipeLockNodeViewStatusSelected;
        [self.selectedNodeArray addObject:nodeView];
        
        [self addLineToNode:nodeView];
		
		if([self.delegate respondsToSelector:@selector(swipeView:didChangeSwipeWithPassword:)]){
		    NSMutableString *password = [NSMutableString new];
            for(LockDroidSwipeLockNodeView *nodeView in self.selectedNodeArray){
                NSString *index = [@(nodeView.tag) stringValue];
                [password appendString:index];
            }
			[self.delegate swipeView:self didChangeSwipeWithPassword:password];
		}
        
        return YES;
    }else{
        return NO;
    }
    }
}

-(void)addLineToNode:(LockDroidSwipeLockNodeView *)nodeView
{
	@autoreleasepool {
    if(self.selectedNodeArray.count == 1){
        
        //path move to start point
        CGPoint startPoint = nodeView.center;
        [self.polygonalLinePath moveToPoint:startPoint];
        [self.pointArray addObject:[NSValue valueWithCGPoint:startPoint]];
        self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
        
    }else{
        
        //path add line to point
        [self.pointArray removeLastObject];
        CGPoint middlePoint = nodeView.center;
        [self.pointArray addObject:[NSValue valueWithCGPoint:middlePoint]];
        
        [self.polygonalLinePath removeAllPoints];
        CGPoint startPoint = [self.pointArray[0] CGPointValue];
        [self.polygonalLinePath moveToPoint:startPoint];
        
        for (int i = 1; i < self.pointArray.count; ++i) {
            CGPoint middlePoint = [self.pointArray[i] CGPointValue];
            [self.polygonalLinePath addLineToPoint:middlePoint];
        }
        self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
        
    }
	}
}

-(void)moveLineWithFingerPosition:(CGPoint)touchPoint
{
	@autoreleasepool {
    if (self.pointArray.count > 0) {
        if (self.pointArray.count > self.selectedNodeArray.count) {
            [self.pointArray removeLastObject];
        }
        [self.pointArray addObject:[NSValue valueWithCGPoint:touchPoint]];
        [self.polygonalLinePath removeAllPoints];
        CGPoint startPoint = [self.pointArray[0] CGPointValue];
        [self.polygonalLinePath moveToPoint:startPoint];
        
        for (int i = 1; i < self.pointArray.count; ++i) {
            CGPoint middlePoint = [self.pointArray[i] CGPointValue];
            [self.polygonalLinePath addLineToPoint:middlePoint];
        }
        self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
    }
	}
}

-(void)removeLastFingerPosition
{
	@autoreleasepool {
    if (self.pointArray.count > 0) {
        if (self.pointArray.count > self.selectedNodeArray.count) {
            [self.pointArray removeLastObject];
        }
        [self.polygonalLinePath removeAllPoints];
        CGPoint startPoint = [self.pointArray[0] CGPointValue];
        [self.polygonalLinePath moveToPoint:startPoint];
        
        for (int i = 1; i < self.pointArray.count; ++i) {
            CGPoint middlePoint = [self.pointArray[i] CGPointValue];
            [self.polygonalLinePath addLineToPoint:middlePoint];
        }
        self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
        
    }
	}
}

-(void)layoutSubviews{
    @autoreleasepool {
    self.polygonalLineLayer.frame = self.bounds;
    CAShapeLayer *maskLayer = [CAShapeLayer new];
    maskLayer.frame = self.bounds;
    
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.bounds];
    maskLayer.fillRule = kCAFillRuleEvenOdd;
    maskLayer.lineWidth = 1.0f;
    maskLayer.strokeColor = [UIColor blackColor].CGColor;
    maskLayer.fillColor = [UIColor blackColor].CGColor;
    //TODO: here should be more decent
    for (int i = 0; i < self.nodeArray.count; ++i) {
        LockDroidSwipeLockNodeView *nodeView = _nodeArray[i];
        // TODO: change to use MIN marco in the future
        CGFloat min = self.bounds.size.width < self.bounds.size.height ? self.bounds.size.width : self.bounds.size.height;
        CGFloat width = min / 4.5f;
        CGFloat height = min / 4.5f;
        int row = i % 3;
        int column = i / 3;
        CGRect frame = CGRectMake((width/4)+(row *(width * 1.5f)), (width/4)+(column * (width * 1.5f)), width, height);
        nodeView.frame = frame;
        [maskPath appendPath:[UIBezierPath bezierPathWithOvalInRect:frame]];
    }
    
    maskLayer.path = maskPath.CGPath;
    self.polygonalLineLayer.mask = maskLayer;
	}
}

-(NSInteger)indexForNodeAtPoint:(CGPoint)point
{
	@autoreleasepool {
    for (int i = 0; i < self.nodeArray.count; ++i) {
        LockDroidSwipeLockNodeView *node = self.nodeArray[i];
        CGPoint pointInNode = [node convertPoint:point fromView:self];
        if ([node pointInside:pointInNode withEvent:nil]) {
            NSLog(@"点中了第%d个~~", i);
            return i;
        }
    }
    return -1;
	}
}

-(void)cleanNodes
{
	@autoreleasepool {
    for (int i = 0; i < self.nodeArray.count; ++i) {
        LockDroidSwipeLockNodeView *node = self.nodeArray[i];
        node.nodeViewStatus = LockDroidSwipeLockNodeViewStatusNormal;
    }
    
    [self.selectedNodeArray removeAllObjects];
    [self.pointArray removeAllObjects];
    self.polygonalLinePath = [UIBezierPath new];
    self.polygonalLineLayer.strokeColor = LIGHTBLUE.CGColor;
    self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
	}
}

-(void)cleanNodesIfNeeded{
    if(self.viewState != LockDroidSwipeLockNodeViewStatusNormal){
        [self cleanNodes];
    }
}

-(void)makeNodesToWarning
{
	@autoreleasepool {
    for (int i = 0; i < self.selectedNodeArray.count; ++i) {
        LockDroidSwipeLockNodeView *node = self.selectedNodeArray[i];
        node.nodeViewStatus = LockDroidSwipeLockNodeViewStatusWarning;
    }
    self.polygonalLineLayer.strokeColor = [UIColor redColor].CGColor;
	}
}

-(void)makeNodesToValid
{
	@autoreleasepool {
    for (int i = 0; i < self.selectedNodeArray.count; ++i) {
        LockDroidSwipeLockNodeView *node = self.selectedNodeArray[i];
        node.nodeViewStatus = LockDroidSwipeLockNodeViewStatusValid;
    }
    self.polygonalLineLayer.strokeColor = [UIColor greenColor].CGColor;
	}
}

-(CAShapeLayer *)polygonalLineLayer
{
	@autoreleasepool {
    if (_polygonalLineLayer == nil) {
        _polygonalLineLayer = [[CAShapeLayer alloc] init];
        _polygonalLineLayer.lineWidth = 5.0f;
        _polygonalLineLayer.strokeColor = LIGHTBLUE.CGColor;
        _polygonalLineLayer.fillColor = [UIColor clearColor].CGColor;
    }
    return _polygonalLineLayer;
	}
}

-(void)setViewState:(LockDroidSwipeLockViewState)viewState
{
	@autoreleasepool {
//    if(_viewState != viewState){
        _viewState = viewState;
        switch (_viewState){
            case LockDroidSwipeLockViewStateNormal:
                [self cleanNodes];
                break;
            case LockDroidSwipeLockViewStateWarning:
                [self makeNodesToWarning];
                [self performSelector:@selector(cleanNodesIfNeeded) withObject:nil afterDelay:1];
                break;
            case LockDroidSwipeLockViewStateSelected:
            default:
                break;
        }
//    }
	}
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
