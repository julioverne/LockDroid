#import "LockDroidSwipeLockNodeView.h"
#import "LockDroidSwipeLockView.h"

@interface LockDroidSwipeLockNodeView()
@property (nonatomic, strong)CAShapeLayer *outlineLayer;
@property (nonatomic, strong)CAShapeLayer *innerCircleLayer;
@property (nonatomic, strong)UIImageView* image;
@end

@implementation LockDroidSwipeLockNodeView
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		if(useImage) {
			self.image = [[UIImageView alloc] init];
			[self addSubview:self.image];
		} else {
			[self.layer addSublayer:self.outlineLayer];
			[self.layer addSublayer:self.innerCircleLayer];
		}
        self.nodeViewStatus = LockDroidSwipeLockNodeViewStatusNormal;
    }
    return self;
}
- (void)setTag:(NSInteger)arg1
{
	[super setTag:arg1];
	NSData* imageData = [NSData dataWithContentsOfFile:[imagePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png", (int)arg1]]];
	if(!imageData) {
		imageData = [NSData dataWithContentsOfFile:[imagePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d.png", 0]]];
	}
	UIImage *image = [[UIImage alloc] initWithData:imageData];
	[self.image setImage:image];
}
-(void)pan:(UIPanGestureRecognizer *)rec
{
    self.nodeViewStatus = LockDroidSwipeLockNodeViewStatusSelected;
}
-(void)setNodeViewStatus:(LockDroidSwipeLockNodeViewStatus)nodeViewStatus
{
    _nodeViewStatus = nodeViewStatus;
    switch (_nodeViewStatus) {
        case LockDroidSwipeLockNodeViewStatusNormal:
            [self setStatusToNormal];
            break;
        case LockDroidSwipeLockNodeViewStatusSelected:
            [self setStatusToSelected];
            break;
        case LockDroidSwipeLockNodeViewStatusWarning:
            [self setStatusToWarning];
            break;
		case LockDroidSwipeLockNodeViewStatusValid:
            [self setStatusToValid];
            break;
        default:
            break;
    }
}
-(void)setStatusToNormal
{
    self.outlineLayer.strokeColor = dotNormalColor.CGColor;
    self.innerCircleLayer.fillColor = dotNormalColor.CGColor;
}
-(void)setStatusToSelected
{
    self.outlineLayer.strokeColor = selectionColor.CGColor;
    self.innerCircleLayer.fillColor = selectionColor.CGColor;
}
-(void)setStatusToWarning
{
    self.outlineLayer.strokeColor = warningColor.CGColor;
    self.innerCircleLayer.fillColor = warningColor.CGColor;
}
-(void)setStatusToValid
{
    self.outlineLayer.strokeColor = validColor.CGColor;
    self.innerCircleLayer.fillColor = validColor.CGColor;
}
-(void)layoutSubviews
{
	self.image.frame = self.bounds;
    self.outlineLayer.frame = self.bounds;
    UIBezierPath *outlinePath = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    self.outlineLayer.path = outlinePath.CGPath;
    
    CGRect frame = self.bounds;
    CGFloat width = frame.size.width / 3;
    self.innerCircleLayer.frame = CGRectMake(width, width, width, width);
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithOvalInRect:self.innerCircleLayer.bounds];
    self.innerCircleLayer.path = innerPath.CGPath;

}
-(CAShapeLayer *)outlineLayer
{
    if (_outlineLayer == nil) {
        _outlineLayer = [[CAShapeLayer alloc] init];
        _outlineLayer.strokeColor = selectionColor.CGColor;
        _outlineLayer.lineWidth = 1.0f;
        _outlineLayer.fillColor  = dotFillColor.CGColor;
    }
    return _outlineLayer;
}
-(CAShapeLayer *)innerCircleLayer
{
    if (_innerCircleLayer == nil) {
        _innerCircleLayer = [[CAShapeLayer alloc] init];
        _innerCircleLayer.strokeColor = [UIColor clearColor].CGColor;
        _innerCircleLayer.lineWidth = 1.0f;
        _innerCircleLayer.fillColor  = selectionColor.CGColor;
    }
    return _innerCircleLayer;
}
@end
