//
//  prowlmenuAppDelegate.m
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

#import "prowlmenuAppDelegate.h"

@implementation prowlmenuAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	
	/*
		If there's no api key, open preferences and about panels.
		It's probably the first time prowlmenu is opened.
	 */
	if ([[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"apikey"] == Nil) {
		[prefWindow makeKeyAndOrderFront:self];
		[aboutWindow makeKeyAndOrderFront:self];
	}
}

-(void)awakeFromNib{

	// setup images
	pmImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"iphone" ofType:@"png"]];
	pmActive = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"iphone_b" ofType:@"png"]];

	// setup status item 
	pmItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[pmItem setMenu:pmMenu];
	[pmItem setImage:pmImage];
	[pmItem setHighlightMode:YES];
	
	// setup about box
	NSBundle *bundle = [NSBundle mainBundle];
	NSString *creditsString = [[[NSString alloc] initWithContentsOfFile:[bundle pathForResource:@"credits" ofType:@"html"]] autorelease];
	NSAttributedString* creditsHTML = [[[NSAttributedString alloc] initWithHTML:[creditsString dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:nil] autorelease];
		// the only way to change the link color
	[credits setLinkTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName,nil]];
	[credits insertText:creditsHTML];
	[credits setEditable:NO];
	
	// to catch changes to the api key field,
	// a change will call controlTextDidChange	
	[apikeyentry setDelegate:self];
	
	[GrowlApplicationBridge setGrowlDelegate: self];
	
	remaining = @"N/A";
}


- (void)controlTextDidChange:(NSNotification *)aNotification
{
    if([aNotification object] == apikeyentry)
    {
		// hide the validation text view, it might me wrong now
		[validation setHidden:YES];
    }
}

- (void)clipboard2iPhone:(id) sender {
	
	NSString *description;

	// get pasteboard contents
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];; 
	NSArray *classes = [[NSArray alloc] initWithObjects:[NSString class], nil];
	NSDictionary *options = [NSDictionary dictionary];
	NSArray *copiedItems = [pasteboard readObjectsForClasses:classes options:options];
	[classes release];
		
	description = [copiedItems objectAtIndex:0];
	[self sendMessage:description];

}

- (void)displayThirdPartyLicenses:(id)sender{
	NSString *FilePath = [[NSBundle mainBundle] pathForResource:@"3rdparty" ofType:@"rtf"];
	NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
	[workspace openFile:FilePath];
	
}


- (void)handleLoginItem:(id)sender {

	/*
		Responsible for creating or destroying a 
		login item for prowlmenu
	 */
	
	BOOL startup = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"systemstartup"] boolValue];
	NSString *programPath = [[NSBundle mainBundle] bundlePath];
	CFURLRef programUrl = (CFURLRef)[NSURL fileURLWithPath:programPath];
    LSSharedFileListItemRef existingLoginItem = NULL;
	
	// get login items for the user (not the global ones)
    LSSharedFileListRef loginItemsList = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    if (loginItemsList) {
        UInt32 seed = 0;
        NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItemsList, &seed)) autorelease];
        for (id itemObject in currentLoginItems) {
            LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
			
            UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
            CFURLRef URL = NULL;
            OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, NULL);
            if (err == noErr) {
                Boolean foundIt = CFEqual(URL, programUrl);
                CFRelease(URL);
				
                if (foundIt) {
                    existingLoginItem = item;
                    break;
                }
            }
        }
		
        if (startup && (existingLoginItem == NULL)) {
            LSSharedFileListItemRef newLoginItem = LSSharedFileListInsertItemURL(loginItemsList, kLSSharedFileListItemBeforeFirst,
																				 NULL, NULL, programUrl, NULL, NULL);
			// we definitely have to release myitem
			if (newLoginItem != NULL)
				CFRelease(newLoginItem);
			
        } else if (!startup && (existingLoginItem != NULL))
            LSSharedFileListItemRemove(loginItemsList, existingLoginItem);
		
        CFRelease(loginItemsList);
    }       
}

- (void)sendMessage:(NSString *)message {
	
	// shorten the description string
	if ([message length] > 1000) {
		message = [message substringToIndex:1000];
	}
	
	// assemble the paramter array ...
	NSArray *params = [ NSArray arrayWithObjects:@"apikey=", [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"apikey"],
					   @"&application=prowlMenu",
					   @"&event=Info",
					   @"&description=",[self urlEncodeString:message], 
					   @"&priority=",[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"prio"], 
					   nil ];
	
	// ... and convert it into a string
	NSString *post = [params componentsJoinedByString:@"" ];
	
	NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
	
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString:@"https://prowl.weks.net/publicapi/add"]];
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:postData];

	NSHTTPURLResponse *response;
	NSData *answerData = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: nil];
	
	statusCode=nil;

	NSXMLParser *addressParser = [[NSXMLParser alloc] initWithData:answerData];
    [addressParser setDelegate:self];
    [addressParser parse]; 
	[addressParser release];
	
	if ([statusCode isEqualToString:@"200"]) {
		
		[GrowlApplicationBridge notifyWithTitle:@"prowlmenu Message sent"
									description:(NSString *)message
							   notificationName:@"prowlmenuSent"
									   iconData:[NSData data]
									   priority:0
									   isSticky:NO
								   clickContext:nil];

	} else {

		NSString *errormessage = @"Unkown error, most probably a connection problem";
		
		if ([statusCode isEqualToString:@"400"]) {
			errormessage = @"Bad request";
		} 
		if ([statusCode isEqualToString:@"401"]) {
			errormessage = @"Not authorized, the API key given is not valid";
		} 
		if ([statusCode isEqualToString:@"405"]) {
			errormessage = @"Method not allowed, you attempted to use a non-SSL connection to Prowl";
		} 
		if ([statusCode isEqualToString:@"406"]) {
			errormessage = @"Not acceptable, your IP address has exceeded the API limit";
		} 
		if ([statusCode isEqualToString:@"500"]) {
			errormessage = @"Internal server error, check again later";
		} 		
		
		[GrowlApplicationBridge notifyWithTitle:@"prowlmenu Error"
									description:errormessage
							   notificationName:@"prowlmenuError"
									   iconData:[NSData data]
									   priority:0
									   isSticky:NO
								   clickContext:nil];	

		NSLog(@"ERROR: %@", errormessage);
		
		// should we do an alert modal in case there is no Growl on the system?
		/*
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"OK"];
		[alert setMessageText:@"prowlmenu problem"];
		[alert setInformativeText:errormessage];
		[alert setAlertStyle:NSWarningAlertStyle];
		[alert runModal];
		*/
	}
	
	[apiCallsLeft setTitle:[NSString stringWithFormat:@"API calls left:  %@", remaining]];

}

- (void) validateAPIKey:(id)sender{
	
	/*	
		GET request for validation:
		https://prowl.weks.net/publicapi/verify?apikey=xxxxxx
	 
		Example of a succesful reply:
	 
		<?xml version="1.0" encoding="UTF-8"?>
		<prowl>
		<success code="200" remaining="983" resetdate="1290046285" />
		</prowl>
	 
		Example of an error reply:
	 
		<?xml version="1.0" encoding="UTF-8"?>
		<prowl>
		<error code="401">Invalid API key</error>
		</prowl>

	*/
	
	// it is better to write the value explicitely here
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[apikeyentry stringValue] forKey:@"apikey"];

	NSArray *urlstring = [ NSArray arrayWithObjects:@"https://prowl.weks.net/publicapi/verify?",
						   @"apikey=", [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"apikey"],
						   nil ];
	
	
	NSString *get = [urlstring componentsJoinedByString:@"" ];
	
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:[NSURL URLWithString: get]];
	
	NSHTTPURLResponse *response;
	NSData *answerData = [NSURLConnection sendSynchronousRequest: request returningResponse: &response error: nil];

	if (answerData==nil) {
		statusCode=@"no connection";
	}else {
		statusCode=Nil;			
	}
	
	NSXMLParser *addressParser = [[NSXMLParser alloc] initWithData:answerData];
    [addressParser setDelegate:self];
    [addressParser parse]; 
	[addressParser release];
	
	if ([statusCode isEqualToString:@"200"]) {
		[validation setHidden:NO];
		[validation setTextColor:[NSColor greenColor]];
		[validation setStringValue:@"OK"];

		[GrowlApplicationBridge notifyWithTitle:@"prowlmenu"
									description:@"API key is valid"
							   notificationName:@"prowlmenuValidation"
									   iconData:[NSData data]
									   priority:0
									   isSticky:NO
								   clickContext:nil];
	} else {
		[validation setHidden:NO];
		[validation setTextColor:[NSColor redColor]];
		[validation setStringValue: [NSString stringWithFormat:@"Failed: %@", statusCode]];
		
		[GrowlApplicationBridge notifyWithTitle:@"prowlmenu"
									description:@"API key could not be validated"
							   notificationName:@"prowlmenuValidation"
									   iconData:[NSData data]
									   priority:0
									   isSticky:NO
								   clickContext:nil];
	}
	
	[apiCallsLeft setTitle:[NSString stringWithFormat:@"API calls left:  %@", remaining]];
}


- (NSString *)urlEncodeString:(NSString *)str {
	// method to create url encoded strings 

	NSString *enc = (NSString *) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, 
																		 (CFStringRef)str, NULL, CFSTR("?=&+"), 
																		 kCFStringEncodingUTF8);
	return [enc autorelease];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI 
							qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	
    if ([elementName isEqualToString:@"error"]) {
        NSString *code = [attributeDict objectForKey:@"code"];
        if (code){
            NSLog(@"API error code: %@",code);
			statusCode=[code copy];
		}
	}
	
	if ([elementName isEqualToString:@"success"]) {
        NSString *code = [attributeDict objectForKey:@"code"];
        if (code){
			statusCode=[code copy];
		}
		NSString *rcounter = [attributeDict objectForKey:@"remaining"];
        if (rcounter){
			remaining = [rcounter copy];
		}
	}
	
}

// Not used
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
}

- (id)performDefaultImplementation {
    // This is called from apple script with a message to send

	// send the direct parameter 
    // NSLog(@"Received apple event \"send message\": '%@'", [self directParameter]);
	[self sendMessage: [self directParameter]];
	return nil;
}
@end
