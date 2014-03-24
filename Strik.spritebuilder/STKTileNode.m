//
//  STKTileNode.m
//  Strik
//
//  Created by Matthijn Dijkstra on 12/03/14.
//  Copyright (c) 2014 Strik. All rights reserved.
//

#import "STKTileNode.h"
#import "STKBoardNode.h"

#import "STKTile.h"
#import "STKBoard.h"

#import "NSObject+Observer.h"

#define SELECTION_ANIMATION_TIME 0.5

@interface STKTileNode()

// The tile for this node
@property (weak) STKTile *tile;

// The board node where this tile is on
@property (weak) STKBoardNode *boardNode;

// The letter label
@property CCLabelTTF *letterLabel;

// The background
@property CCNodeColor *background;

// When this flag is set we are animating!
@property (nonatomic) BOOL isAnimating;

// If there is a shadow, it will be placed in here
@property CCNode *shadowContainer;

@end

@implementation STKTileNode

+ (id)newTileNodeWithTile:(STKTile *)tile andBoardNode:(STKBoardNode *)boardNode
{
	STKTileNode *tileNode = (STKTileNode *)[CCBReader load:@"Game Scene/Tile.ccbi"];
	
	// Set the tile and listen for changes
	tileNode.tile = tile;
	[tileNode observeModel:tile];
	
	// Set tilenode on tile
	tile.node = tileNode;
	
	// Set the board node
	tileNode.boardNode = boardNode;
	
	return tileNode;
}

#pragma mark Model state changes
- (void)tile:(STKTile *)tile valueChangedForLetter:(NSNumber *)letter
{
	self.letterLabel.string = [NSString stringWithFormat:@"%c", tile.letter];
}

- (void)tile:(STKTile *)tile valueChangedForIsRemoved:(NSNumber *)isRemoved
{
	// Only remove now when we are not animating anything else
    if([isRemoved boolValue] && !self.isAnimating)
    {
        [self animateToRemovedState];
    }
}

- (void)tile:(STKTile *)tile valueChangedForSelectedBy:(NSNumber *)player
{
    // Determine who have selected it
    BOOL byPlayer = [tile isSelectedBy:tile.board.player];
    BOOL byOpponent = [tile isSelectedBy:tile.board.opponent];
	
    // Process it
    [self animateToSelectedByPlayer:byPlayer andOpponent:byOpponent];
}

#pragma mark animation
- (void)animateToNormalState
{
	[self animateToBackgroundColor:[CCColor colorWithWhite:244.0f/255.0f alpha:1] andLabelColor:[CCColor colorWithRed:61.0f/255.0f green:60.0f/255.0f blue:62.0f/255.0f]];
}

- (void)animateToRemovedState
{
	[self removeFromParent];
}

- (void)animateToSelectedByPlayer:(BOOL)byPlayer andOpponent:(BOOL)byOpponent
{
	// Selected by none, we can animate to normal state
	if(!byPlayer && !byOpponent)
	{
		[self animateToNormalState];
	}
	else
	{
		if(byPlayer)
		{
			[self animateToBackgroundColor:PLAYER_ONE_COLOR andLabelColor:[CCColor whiteColor]];
		}
		else if(byOpponent)
		{
			[self animateToBackgroundColor:PLAYER_TWO_COLOR andLabelColor:[CCColor whiteColor]];
		}
	}
}

- (void)dealloc
{
	[self removeAsObserverForAllModels];
}

#pragma mark CCACtion getters (for lazy loading)
- (void)animateToBackgroundColor:(CCColor *)backgroundColor andLabelColor:(CCColor *)labelColor
{
	// Setting flag for animating
	self.isAnimating = YES;
	
	// Putting the block at the end for the animation so we no when we stopped animating
	CCActionCallBlock *animationCompleted = [CCActionCallBlock actionWithBlock:^{
		self.isAnimating = NO;
	}];
	
	CCActionSequence *sequence = [CCActionSequence actionWithArray:@[[CCActionTintTo actionWithDuration:SELECTION_ANIMATION_TIME color:backgroundColor], animationCompleted]];
	
	// Can't run the action on the element itself, it should be on label and background
	[self.background runAction:sequence];
//	[self.letterLabel runAction:[CCActionTintTo actionWithDuration:SELECTION_ANIMATION_TIME color:labelColor]];
	self.letterLabel.fontColor = labelColor;
}

- (void)setIsAnimating:(BOOL)isAnimating
{
	_isAnimating = isAnimating;
	
	// We should be removed but we were busy animating!
	if(!isAnimating && self.tile.isRemoved)
	{
		[self animateToRemovedState];
	}
}

#pragma mark Shadows
// Clear the shadows from this tile
- (void)clearShadows
{
	NSArray *children = [NSArray arrayWithArray:self.shadowContainer.children];
	for(CCNode *child in children)
	{
		[child removeFromParent];
	}
}

- (void)addShadowForPosition:(ShadowPosition)shadowPosition
{
	CCSprite *shadowSprite = [CCSprite spriteWithImageNamed:@"Game Scene/shadow.png"];
	
	// Center it
	shadowSprite.anchorPoint = CGPointMake(0.5, 0.5);
	
	shadowSprite.positionType = CCPositionTypeNormalized;
	shadowSprite.position = CGPointMake(0.5, 0.5);
	
	// Rotate it based on position
	static int rotations[4] = {0, 90, 180, 270};
	shadowSprite.rotation = rotations[shadowPosition];
	
	// And add
	[self.shadowContainer addChild:shadowSprite];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<STKTileNode with tile> %@", [self.tile description]];
}

@end
