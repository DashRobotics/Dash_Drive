/*

 File: LeDiscovery.m
 
 Abstract: Scan for and discover nearby LE peripherals with the 
 matching service UUID.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
 Apple Inc. ("Apple") in consideration of your agreement to the
 following terms, and your use, installation, modification or
 redistribution of this Apple software constitutes acceptance of these
 terms.  If you do not agree with these terms, please do not use,
 install, modify or redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. 
 may be used to endorse or promote products derived from the Apple
 Software without specific prior written permission from Apple.  Except
 as expressly stated in this notice, no other rights or licenses, express
 or implied, are granted by Apple herein, including but not limited to
 any patent rights that may be infringed by your derivative works or by
 other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */



#import "LeDiscovery.h"
#import "DRRobotLeService.h"

@interface LeDiscovery () <CBCentralManagerDelegate, CBPeripheralDelegate> {
	CBCentralManager    *_centralManager;
	BOOL				_pendingInit;
}
@end


@implementation LeDiscovery

#pragma mark -
#pragma mark Init
/****************************************************************************/
/*									Init									*/
/****************************************************************************/
//+ (id) sharedInstance
//{
//	static LeDiscovery *this = nil;
//
//	if (!this)
//		this = [[LeDiscovery alloc] init];
//
//	return this;
//}
+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    
    dispatch_once(&once, ^
                  {
                      sharedInstance = [self new];
                  });
    
    return sharedInstance;
}

- (id) init
{
    self = [super init];
    if (self) {
		_pendingInit = YES;
		_centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];

		self.foundPeripherals = [[NSMutableArray alloc] init];
		self.connectedServices = [[NSMutableArray alloc] init];
	}
    return self;
}


- (void) dealloc
{
    // We are a singleton and as such, dealloc shouldn't be called.
    assert(NO);
}

- (id) serviceForPeripheral:(CBPeripheral *)peripheral
{
    for (DRRobotLeService *service in self.connectedServices) {
        if ( [[service peripheral] isEqual:peripheral] ) {
            return service;
        }
    }
    
    return nil;
}


#pragma mark -
#pragma mark Restoring
/****************************************************************************/
/*								Settings									*/
/****************************************************************************/
/* Reload from file. */
- (void) loadSavedDevices
{
	NSArray	*storedDevices	= [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];

	if (![storedDevices isKindOfClass:[NSArray class]]) {
        NSLog(@"No stored array to load");
        return;
    }
     
    for (id deviceUUIDString in storedDevices) {
        
        if (![deviceUUIDString isKindOfClass:[NSString class]])
            continue;
        
        CFUUIDRef uuid = CFUUIDCreateFromString(NULL, (CFStringRef)deviceUUIDString);
        if (!uuid)
            continue;
        
        [_centralManager retrievePeripheralsWithIdentifiers:@[(__bridge id)uuid]];
        CFRelease(uuid);
    }

}


- (void) addSavedDevice:(CFUUIDRef) uuid
{
	NSArray			*storedDevices	= [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];
	NSMutableArray	*newDevices		= nil;
	CFStringRef		uuidString		= NULL;

	if (![storedDevices isKindOfClass:[NSArray class]]) {
        NSLog(@"Can't find/create an array to store the uuid");
        return;
    }

    newDevices = [NSMutableArray arrayWithArray:storedDevices];
    
    uuidString = CFUUIDCreateString(NULL, uuid);
    if (uuidString) {
        [newDevices addObject:(__bridge NSString*)uuidString];
        CFRelease(uuidString);
    }
    /* Store */
    [[NSUserDefaults standardUserDefaults] setObject:newDevices forKey:@"StoredDevices"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void) removeSavedDevice:(CFUUIDRef) uuid
{
	NSArray			*storedDevices	= [[NSUserDefaults standardUserDefaults] arrayForKey:@"StoredDevices"];
	NSMutableArray	*newDevices		= nil;
	CFStringRef		uuidString		= NULL;

	if ([storedDevices isKindOfClass:[NSArray class]]) {
		newDevices = [NSMutableArray arrayWithArray:storedDevices];

		uuidString = CFUUIDCreateString(NULL, uuid);
		if (uuidString) {
			[newDevices removeObject:(__bridge NSString*)uuidString];
            CFRelease(uuidString);
        }
		/* Store */
		[[NSUserDefaults standardUserDefaults] setObject:newDevices forKey:@"StoredDevices"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}


- (void) centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
	for (CBPeripheral *peripheral in peripherals) {
		[central connectPeripheral:peripheral options:nil];
	}
	[self.discoveryDelegate discoveryDidRefresh];
}

- (void) centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    
	for (CBPeripheral *peripheral in peripherals) {
        [central connectPeripheral:peripheral options:nil];
	}
	[self.discoveryDelegate discoveryDidRefresh];
}

- (void) centralManager:(CBCentralManager *)central didFailToRetrievePeripheralForUUID:(CFUUIDRef)UUID error:(NSError *)error
{
	/* Nuke from plist. */
	[self removeSavedDevice:UUID];
}



#pragma mark -
#pragma mark Discovery
/****************************************************************************/
/*								Discovery                                   */
/****************************************************************************/
- (void) startScanningForUUIDString:(NSString *)uuidString
{
	NSArray			*uuidArray	= @[[CBUUID UUIDWithString:uuidString]];
	NSDictionary	*options	= @{CBCentralManagerScanOptionAllowDuplicatesKey: @NO};

	[_centralManager scanForPeripheralsWithServices:uuidArray options:options];
    
    NSLog(@"Started scanning.");
}


- (void) stopScanning
{
	[_centralManager stopScan];
    NSLog(@"Stopped scanning.");
}


- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
	if (![self.foundPeripherals containsObject:peripheral]) {
		[self.foundPeripherals addObject:peripheral];
		[self.discoveryDelegate discoveryDidRefresh];
	}
}



#pragma mark -
#pragma mark Connection/Disconnection
/****************************************************************************/
/*						Connection/Disconnection                            */
/****************************************************************************/
- (void) connectPeripheral:(CBPeripheral*)peripheral
{
	if (peripheral.state == CBPeripheralStateDisconnected) {
		[_centralManager connectPeripheral:peripheral options:nil];
	}
}


- (void) disconnectPeripheral:(CBPeripheral*)peripheral
{
	[_centralManager cancelPeripheralConnection:peripheral];
}


- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
	DRRobotLeService *service = nil;
	
	/* Create a service instance. */
	service = [[DRRobotLeService alloc] initWithPeripheral:peripheral];
	[service start];

	if (![self.connectedServices containsObject:service])
		[self.connectedServices addObject:service];

	if ([self.foundPeripherals containsObject:peripheral])
		[self.foundPeripherals removeObject:peripheral];
    
	[self.discoveryDelegate discoveryDidRefresh];
    [self.discoveryDelegate serviceDidChangeStatus:service];
}


- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Attempted connection to peripheral %@ failed: %@", [peripheral name], [error localizedDescription]);
}


- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
	DRRobotLeService *service = nil;

	for (service in self.connectedServices) {
		if ([service peripheral] == peripheral) {
			[self.connectedServices removeObject:service];
            [self.discoveryDelegate serviceDidChangeStatus:service];
			break;
		}
	}

	[self.discoveryDelegate discoveryDidRefresh];
}

- (void)disconnectAllPeripherals
{
    for (DRRobotLeService *service in self.connectedServices) {
        [service reset];
        service.isManuallyDisconnecting = YES;
        [self performSelector:@selector(disconnectPeripheral:) withObject:service.peripheral afterDelay:0.1];
    }
}

- (void)resetConnectedServices {
    for (DRRobotLeService *service in self.connectedServices) {
        [service reset];
    }
}

- (void) clearDevices
{
    [self.foundPeripherals removeAllObjects];
    for (DRRobotLeService *service in self.connectedServices) {
        [service reset];
        service.isManuallyDisconnecting = YES;
    }
    [self.connectedServices removeAllObjects];
}


- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    static CBCentralManagerState previousState = CBCentralManagerStateUnknown;
    
	switch ([_centralManager state]) {
		case CBCentralManagerStatePoweredOff:
		{
            [self clearDevices];
            [self.discoveryDelegate discoveryDidRefresh];
            
			/* Tell user to power ON BT for functionality, but not on first run - the Framework will alert in that instance. */
            if (previousState != CBCentralManagerStateUnknown) {
                [self.discoveryDelegate discoveryStatePoweredOff];
            }
			break;
		}
            
        case CBCentralManagerStateUnsupported:
		case CBCentralManagerStateUnauthorized:
		{
			/* Tell user the app is not allowed. */
			break;
		}
            
		case CBCentralManagerStateUnknown:
		{
			/* Bad news, let's wait for another event. */
			break;
		}
            
		case CBCentralManagerStatePoweredOn:
		{
			_pendingInit = NO;
			[self loadSavedDevices];
//			[_centralManager retrieveConnectedPeripherals];
            [_centralManager retrieveConnectedPeripheralsWithServices:@[kBiscuitServiceUUIDString]];
			[self.discoveryDelegate discoveryDidRefresh];
			break;
		}
            
		case CBCentralManagerStateResetting:
		{
			[self clearDevices];
            [self.discoveryDelegate discoveryDidRefresh];
//            [peripheralDelegate alarmServiceDidReset];
            
			_pendingInit = YES;
			break;
		}
	}
    
    previousState = [_centralManager state];
}
@end
