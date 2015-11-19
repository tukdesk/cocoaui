/*
 Copyright (c) 2014 ideawu. All rights reserved.
 Use of this source code is governed by a license that can be
 found in the LICENSE file.
 
 @author:  ideawu
 @website: http://www.cocoaui.com/
 */

#import "IKitUtil.h"
#import "Text.h"

@implementation IKitUtil

static NSString *substr(NSString *str, NSUInteger offset, NSUInteger len){
	return [str substringWithRange:NSMakeRange(offset, len)];
}

static CGFloat colorVal(NSString *hex){
	hex = (hex.length == 2) ? hex : [NSString stringWithFormat:@"%@%@", hex, hex];
	unsigned num;
	[[NSScanner scannerWithString:hex] scanHexInt:&num];
	return num / 255.0;
}

+ (UIColor *)colorFromHex:(NSString *)hex {
	if([hex isEqualToString:@"none"]){
		return [UIColor clearColor];
	}
	if([hex characterAtIndex:0] == '#'){
		hex = [hex substringFromIndex:1];
	}
	
	CGFloat alpha, red, blue, green;
	switch ([hex length]) {
		case 3: // #RGB
			alpha = 1.0f;
			red   = colorVal(substr(hex, 0, 1));
			green = colorVal(substr(hex, 1, 1));
			blue  = colorVal(substr(hex, 2, 1));
			break;
		case 4: // #ARGB
			alpha = colorVal(substr(hex, 0, 1));
			red   = colorVal(substr(hex, 1, 1));
			green = colorVal(substr(hex, 2, 1));
			blue  = colorVal(substr(hex, 3, 1));
			break;
		case 6: // #RRGGBB
			alpha = 1.0f;
			red   = colorVal(substr(hex, 0, 2));
			green = colorVal(substr(hex, 2, 2));
			blue  = colorVal(substr(hex, 4, 2));
			break;
		case 8: // #AARRGGBB
			alpha = colorVal(substr(hex, 0, 2));
			red   = colorVal(substr(hex, 2, 2));
			green = colorVal(substr(hex, 4, 2));
			blue  = colorVal(substr(hex, 6, 2));
			break;
		default:
			return [UIColor clearColor];
			break;
	}
	return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

+ (UIColor *)colorFromRGBA: (NSString *)rgba {
    if([rgba rangeOfString:@"rgba("].location != NSNotFound){
        rgba = [rgba substringFromIndex:5];
        static NSCharacterSet *cs = nil;
        if(!cs){
            cs = [NSCharacterSet characterSetWithCharactersInString:@")"];
        }
        rgba = [rgba stringByTrimmingCharactersInSet:cs];
    }
    NSArray *vals = [rgba componentsSeparatedByString:@","];
                     
    
    if ([vals count] != 4) {
        return [UIColor clearColor];
    }
    
    CGFloat red = [[vals[0] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] floatValue] / 255.0;
    CGFloat green = [[vals[0] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] floatValue] / 255.0;
    CGFloat blue = [[vals[0] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] floatValue] / 255.0;
    CGFloat alpha = [[vals[0] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] floatValue];
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

+ (BOOL)isHTML:(NSString *)str{
	if([str rangeOfString:@"</html>"].length > 0 || [str rangeOfString:@"</HTML>"].length > 0){
		if([str rangeOfString:@"</body>"].length > 0 || [str rangeOfString:@"</BODY>"].length > 0){
			return YES;
		}
	}
	return NO;
}

+ (BOOL)isHttpUrl:(NSString *)src{
	if(!src){
		return NO;
	}
	if([src rangeOfString:@"http://"].location == 0 || [src rangeOfString:@"https://"].location == 0){
		return YES;
	}
	return NO;
}

+ (NSArray *)parsePath:(NSString *)url{
	NSString *basePath, *rootPath;
	NSRange r1 = [url rangeOfString:@"http://"];
	if(r1.location != 0){
		r1 = [url rangeOfString:@"https://"];
	}
	NSRange r2 = [url rangeOfString:@"/" options:NSBackwardsSearch];
	if(r1.location != 0){ // File path
		if(r2.location == NSNotFound){
			rootPath = [NSString stringWithFormat:@"%@/", [[NSBundle mainBundle] resourcePath]];
			basePath = rootPath;
		}else{
			rootPath = [url substringToIndex:r2.location + 1];
			basePath = rootPath;
		}
	}else{ // HTTP URL
		if(r2.location < r1.location + r1.length){ // like http://cocoaui.com
			basePath = [NSString stringWithFormat:@"%@/", url];
			rootPath = basePath;
		}else{
			basePath = [url substringToIndex:r2.location + 1];
			NSUInteger idx = r1.location + r1.length;
			while(idx < url.length){
				if([url characterAtIndex:idx] == '/'){
					break;
				}
				idx ++;
			}
			rootPath = [url substringToIndex:idx + 1];
		}
	}
	return [NSArray arrayWithObjects:rootPath, basePath, nil];
}

+ (NSString *)buildPath:(NSString *)basePath src:(NSString *)src{
	if([IKitUtil isHttpUrl:basePath]){
		if([IKitUtil isHttpUrl:src]){
			return src;
		}
		if([src characterAtIndex:0] == '/'){
			NSArray *arr = [IKitUtil parsePath:basePath];
			NSString *rootPath = [arr objectAtIndex:0];
			src = [rootPath stringByAppendingString:[src substringFromIndex:1]];
		}else{
			src = [basePath stringByAppendingString:src];
		}
	}else{
		src = [basePath stringByAppendingString:src];
	}
	return src;
}

+ (UIImage *)loadImageFromPath:(NSString *)path{
	UIImage *img;
	if([IKitUtil isHttpUrl:path]){
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		[request setHTTPMethod:@"GET"];
		[request setURL:[NSURL URLWithString:path]];
		NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
		if(data){
			img = [UIImage imageWithData:data];
		}
	}else{
		if([path characterAtIndex:0] == '/'){
			NSData *data = [NSData dataWithContentsOfFile:path];
			if(data){
				img = [UIImage imageWithData:data];
			}
		}else{
			img = [UIImage imageNamed:path];
		}
	}
	return img;
}

+ (BOOL)isDataURI:(NSString *)src{
	NSRange range = [src rangeOfString:@"data:"];
	if(range.location == 0 && range.length > 0){
		return YES;
	}else{
		return NO;
	}
}

+ (UIImage *)loadImageFromDataURI:(NSString *)src{
	NSRange range = [src rangeOfString:@";base64,"];
	if(range.length > 0){
		NSString *str = [src substringFromIndex:range.location + range.length];
		NSData *data = base64_decode(str);
		//NSLog(@"%@", str);
		return [UIImage imageWithData:data];
	}
	return nil;
}

@end
