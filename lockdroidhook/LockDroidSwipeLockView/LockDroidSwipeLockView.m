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
        
        _nodeArray = [NSMutableArray arrayWithCapacity:(matrix*matrix)];
        for (int i = 0; i < (matrix*matrix); ++i) {
            LockDroidSwipeLockNodeView *nodeView = [LockDroidSwipeLockNodeView new];
            [_nodeArray addObject:nodeView];
            nodeView.tag = i;
            [self addSubview:nodeView];
        }
        _selectedNodeArray = [NSMutableArray arrayWithCapacity:(matrix*matrix)];
        _pointArray = [NSMutableArray array];
		
		
        
        UIPanGestureRecognizer *panRec = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:panRec];
        self.viewState = (LockDroidSwipeLockViewState)LockDroidSwipeLockNodeViewStatusNormal;
        [self cleanNodes];
        
    }
    return self;
}

-(void)pan:(UIPanGestureRecognizer *)rec
{
	@autoreleasepool {
    if  (rec.state == UIGestureRecognizerStateBegan){
        self.viewState = (LockDroidSwipeLockViewState)LockDroidSwipeLockNodeViewStatusNormal;
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
            self.viewState = (LockDroidSwipeLockViewState)LockDroidSwipeLockViewStateSelected;
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
	
	CGFloat min = self.bounds.size.width < self.bounds.size.height ? self.bounds.size.width : self.bounds.size.height;
	float param1;
	float param2;
	float param3;
	
	if(matrix == 3) {
		param1 = 4.5f;
		param2 = 4;
		param3 = 1.5f;
	} else if(matrix == 4) {
		param1 = 5.5f;
		param2 = 5;
		param3 = 1.35f;
	} else if(matrix == 5) {
		param1 = 6.5f;
		param2 = 6;
		param3 = 1.30f;
	}
	
    for (int i = 0; i < self.nodeArray.count; ++i) {
        LockDroidSwipeLockNodeView *nodeView = _nodeArray[i];
		int row = i % matrix;
        int column = i / matrix;
		
        CGFloat width = min / param1;
        CGFloat height = min / param1;
		CGRect frame = CGRectMake((width/param2)+(row *(width * param3)), (width/param2)+(column * (width * param3)), width, height);
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
    self.polygonalLineLayer.strokeColor = selectionColor.CGColor;
    self.polygonalLineLayer.path = self.polygonalLinePath.CGPath;
	}
}

-(void)cleanNodesIfNeeded{
    if(self.viewState != (LockDroidSwipeLockViewState)LockDroidSwipeLockNodeViewStatusNormal){
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
    self.polygonalLineLayer.strokeColor = warningColor.CGColor;
	}
}

-(void)makeNodesToValid
{
	@autoreleasepool {
    for (int i = 0; i < self.selectedNodeArray.count; ++i) {
        LockDroidSwipeLockNodeView *node = self.selectedNodeArray[i];
        node.nodeViewStatus = LockDroidSwipeLockNodeViewStatusValid;
    }
    self.polygonalLineLayer.strokeColor = validColor.CGColor;
	}
}

-(CAShapeLayer *)polygonalLineLayer
{
	@autoreleasepool {
    if (_polygonalLineLayer == nil) {
        _polygonalLineLayer = [[CAShapeLayer alloc] init];
        _polygonalLineLayer.lineWidth = 5.0f;
        _polygonalLineLayer.strokeColor = selectionColor.CGColor;
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
