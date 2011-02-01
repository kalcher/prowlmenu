//
//  prowlmenuAppDelegate.h
//  prowlmenu
//
//  Created by Sebastian Kalcher on 17.11.10.
//  Copyright (c) 2010, Sebastian Kalcher. 
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//  * Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  * Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//  * Neither the name of Sebastian Kalcher nor the names of the contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
// 
//  THIS SOFTWARE IS PROVIDED BY COPYRIGHT HOLDERS ''AS IS'' AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL SEBASTIAN KALCHER BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import <Cocoa/Cocoa.h>
#import <Growl/Growl.h>


@interface prowlmenuAppDelegate : NSScriptCommand <NSApplicationDelegate, 
												   NSXMLParserDelegate, 
												   NSTextFieldDelegate, 
												   GrowlApplicationBridgeDelegate> 
{
    NSWindow				*window;
	NSStatusItem			*pmItem;

	IBOutlet NSMenu			*pmMenu;
	IBOutlet NSTextView		*credits;
	IBOutlet NSTextField	*apikeyentry;
	IBOutlet NSTextField	*validation;
	IBOutlet NSWindow		*aboutWindow;
	IBOutlet NSWindow		*prefWindow;
	IBOutlet NSMenuItem		*apiCallsLeft;
	
	NSImage					*pmImage;
	NSImage					*pmActive;
	
	NSString				*statusCode;
	NSString				*remaining;
}


- (void)validateAPIKey:(id)sender;
- (void)clipboard2iPhone:(id)sender;
- (void)handleLoginItem:(id)sender;
- (void)displayThirdPartyLicenses:(id)sender;

- (void)sendMessage:(NSString *)message;

- (NSString *)urlEncodeString:(NSString *)str;

- (id)performDefaultImplementation;

@property (assign) IBOutlet NSWindow *window;

@end
