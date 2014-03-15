//
//  STKGameController.m
//  Strik
//
//  Created by Matthijn Dijkstra on 10/03/14.
//  Copyright (c) 2014 Strik. All rights reserved.
//

#import "STKGameController.h"
#import "STKGameScene.h"
#import "STKBoardNode.h"

#import "STKMatchPlayer.h"
#import "STKMatch.h"
#import "STKPLayer.h"
#import "STKBoard.h"
#import "STKTile.h"

#import "STKMatchController.h"

#import "STKIncomingMessage.h"

#import "NSObject+Observer.h"

#import "STKAlertView.h"

@interface STKGameController()

// For easier access
@property (readonly) STKMatch *match;
@property (readonly) STKMatchController *matchController;
@property (readonly) STKGameScene *gameScene;
@property (readonly) STKBoard *board;

@end

@implementation STKGameController

- (void)sceneCreated
{
	// Set match for scene so it can listen to changes
    STKGameScene *gameScene = self.scene;
    gameScene.match = self.matchController.match;
	
    // Network events
	
	// Match related
	[self routeNetMessagesOf:MATCH_STARTED to:@selector(matchDidStart:)];
    [self routeNetMessagesOf:MATCH_ENDED to:@selector(matchDidEnd:)];
	
	// Board releated
	[self routeNetMessagesOf:BOARD_INIT to:@selector(setupBoard:)];
    [self routeNetMessagesOf:BOARD_UPDATE to:@selector(handleBoardUpdates:)];
    [self routeNetMessagesOf:WORD_FOUND to:@selector(handleWordFound:)];
}

#pragma mark networking
- (void)setupBoard:(STKIncomingMessage *)message
{
	// Setup the board
	CGSize boardSize = CGSizeMake([message readByte], [message readByte]);
	
	STKBoard *board = [STKBoard boardWithSize:boardSize player:self.match.player andOpponent:self.match.opponent];
	self.match.board = board;
	
	// Add board to board node
	self.gameScene.boardNode.board = board;
	
	// Get every tile and put it in freshtiles so the board node knows there are new tiles
	NSMutableArray *freshTiles = [NSMutableArray arrayWithCapacity:board.size.width * board.size.height];
	for(int col = 0; col < board.size.width; col++)
	{
		for(int row = 0; row  < board.size.height; row++)
		{
			// Get the tile (if there is one)
			SInt8 tileId = [message readByte];
			if(tileId != 0)
			{
				// Create a new tile for this id
				STKTile *tile = [STKTile tileForBoard:board column:col andTileId:tileId];
				tile.letter = [message readByte];
				[freshTiles addObject:tile];
			}
		}
	}
	
	// Set the fresh tiles so the board node can pick it up
	[board addNewTiles:freshTiles];
}

- (void)handleBoardUpdates:(STKIncomingMessage *)message
{
	// First remove old tiles
	int removedTilesCount = [message readByte];
	if(removedTilesCount > 0)
	{
		// Tiles are removed as a group
		NSMutableArray *tilesToRemove = [NSMutableArray array];
		
		for(int i = 0; i < removedTilesCount; i++)
		{
			STKTile *tile = [self.board tileWithTileId:[message readByte]];
			if(tile)
			{
				[tilesToRemove addObject:tile];
			}
		}
		
		// And remove tiles from board
		[self.board removeTiles:tilesToRemove];
	}
	
	// And perhaps add some new!
	int newTilesCount = [message readByte];
	if(newTilesCount > 0)
	{
		// New tiles are added as a group too!
		NSMutableArray *freshTiles = [NSMutableArray array];
		
		for(int i = 0; i < newTilesCount; i++)
		{
			// Get the information for this tile
			SInt8 tileId = [message readByte];
			int collumn = [message readByte];
			char letter = [message readByte];
			
			// Create a tile from information
			STKTile *tile = [STKTile tileForBoard:self.board column:collumn andTileId:tileId];
			tile.letter = letter;
			
			[freshTiles addObject:tile];
		}
		
		// And add em all to the board
		[self.board addNewTiles:freshTiles];
	}
}

- (void)handleWordFound:(STKIncomingMessage *)message
{
	// Retrieve player that found the word
	STKMatch* match = self.matchController.match;
	STKMatchPlayer* player = [match playerByID:[message readByte]];
	
	// Parse the found word & score
	NSString* word = [message readStr];
	int points = [message readInt];
	
	NSLog(@"MatchGameScene: %@ found %@ (%d points)", player.info.name, word, points);
	
	// Get all the tiles for this word
	NSMutableArray *tilesForWord = [NSMutableArray array];
	int numberOfTiles = [message readByte];
	for(int i = 0; i < numberOfTiles; i++)
	{
		SInt8 tileId = [message readByte];
		STKTile *tile = [self.board tileWithTileId:tileId];
		if(tile)
		{
			[tilesForWord addObject:tile];
		}
	}
	
	// Animate word found
	[self.board wordFoundWithTiles:tilesForWord byPlayer:player];
	
	// Boost the score
	player.score += points;
}

- (void)matchDidStart:(STKIncomingMessage *)message
{
	// Start the timer!
	[self.gameScene startTimer];
}

- (void)matchDidEnd:(STKIncomingMessage *)message
{
	if(self.match)
	{
		// Determine winner
		STKMatchPlayer* winner = [self.match playerByID:[message readByte]];
		
		// Clear match
		STKMatchController *matchController = self.core[@"match"];
		
		// Aaaand it's gone
		matchController.match = nil;
		NSLog(@"Match: ended!");
		
		
		// Show statistics from the match
		// STKDirector *director = self.core[@"director"];
		// Todo: present match ended scene
		//		[director presentScene:[STKMatchEndedScene class]];
		
		// Show result alert
		NSString* resultMessage;
		if(winner)
		{
			resultMessage = [NSString stringWithFormat:@"%@ won!", winner.info.name];
		}
		else
		{
			resultMessage = @"Draw!";
		}
		
		[[STKAlertView alertWithTitle:@"Match Ended" andMessage:resultMessage] show];
	}
}

#pragma mark user events

// For easier access
- (STKMatch *)match
{
	return self.matchController.match;
}

- (STKMatchController *)matchController
{
	return self.core[@"match"];
}

- (STKGameScene *)gameScene
{
	return self.scene;
}

- (STKBoard *)board
{
	return self.match.board;
}

@end
