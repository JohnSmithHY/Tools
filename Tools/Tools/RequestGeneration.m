//
//  RequestGeneration.m
//  Tools
//
//  Created by Alex xiang on 15/1/31.
//  Copyright (c) 2015年 Alex xiang. All rights reserved.
//

#import "RequestGeneration.h"

@implementation RequestGeneration
static NSArray *enumList;
static NSDictionary *configDictionary;
/**
 * @brief  Model类自动生成
 * @prama  sourcepath:资源路径   outputPath:资源生成路径
 */
+ (void)generationSourcePath:(NSString *)sourcepath outputPath:(NSString *)outputPath config:(NSDictionary *)config
{
    configDictionary = config;
    NSError *error;
    NSString *sourceString = [[NSString alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForAuxiliaryExecutable:sourcepath] encoding:NSUTF8StringEncoding error:&error];
    
    NSMutableString *h = [[NSMutableString alloc] init];
    NSMutableString *m = [[NSMutableString alloc] init];
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSString *hFilePath = [outputPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@Request.h", configDictionary[@"filename"]]];
    NSString *mFilePath = [outputPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@Request.m", configDictionary[@"filename"]]];
    [fileManager createFileAtPath:hFilePath contents:nil attributes:nil];
    [fileManager createFileAtPath:mFilePath contents:nil attributes:nil];
    
    //版权信息的导入
    [h appendString:[Utils createCopyrightByFilename:[NSString stringWithFormat:@"%@Request.h", configDictionary[@"filename"]] config:config]];
    [m appendString:[Utils createCopyrightByFilename:[NSString stringWithFormat:@"%@Request.m", configDictionary[@"filename"]] config:config]];
    
    //头文件的导入
    [h appendString:[self introductionPackages:H_FILE]];
    [m appendString:[self introductionPackages:M_FILE]];
    
    enumList = [Utils enumList:sourceString];
    
    //导入基本的 实现
    [h appendString:[self classOfRequest:H_FILE]];
    [m appendString:[self classOfRequest:M_FILE]];
    
    //匹配出所有的Request类型
    [h appendString:[self messageFromSourceString:sourceString fileType:H_FILE]];
    [m appendString:[self messageFromSourceString:sourceString fileType:M_FILE]];
    
    
    [h appendFormat:@"#pragma clang diagnostic pop\n"];
    [m appendFormat:@"#pragma clang diagnostic pop\n"];
    [h appendFormat:@"\n@end\n\n\n"];
    [m appendFormat:@"\n@end\n\n\n"];
    
    [h writeToFile:hFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [m writeToFile:mFilePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

/**
 * @brief  导入头文件
 * @prama  fileType:[H_FILE:h文件  M_FILE: m文件]
 **/
+ (NSString *)introductionPackages:(FileType)fileType
{
    NSMutableString *result = [[NSMutableString alloc] init];
    switch (fileType) {
        case H_FILE:
        {
            if ([configDictionary[@"pods"] boolValue]) {
                [result appendString:@"#import <AFNetworking/AFNetworking.h>\n"];
                if ([configDictionary[@"response"] isEqualToString:@"xml"]) {
                    [result appendString:@"#import <XMLDictionary/XMLDictionary.h>\n"];
                }
                [result appendFormat:@"#import <SVProgressHUD/SVProgressHUD.h>\n"];
            }
            else {
                [result appendString:@"#import \"AFNetworking.h\"\n"];
                if ([configDictionary[@"response"] isEqualToString:@"xml"]) {
                    [result appendString:@"#import \"XMLDictionary.h\"\n"];
                }
                [result appendFormat:@"#import \"SVProgressHUD.h\"\n"];
                [result appendFormat:@"#import \"NSDictionary+Safe.h\"\n"];
            }
            [result appendFormat:@"#import <YLT_BaseLib/YLT_BaseLib.h>\n"];
            [result appendFormat:@"#import \"%@Model.h\"\n", configDictionary[@"filename"]];
            
        }
            break;
        case M_FILE:
        {
            [result appendFormat:@"#import \"PHTools.h\"\n"];
            [result appendFormat:@"#import \"%@Request.h\"\n", configDictionary[@"filename"]];
        }
            break;
            
        default:
            break;
    }
    
    return result;
}

/**
 * @brief  Request 基本类的功能
 * @prama  fileType:[H_FILE:h文件  M_FILE: m文件]
 **/
+ (NSString *)classOfRequest:(FileType)fileType
{
    NSMutableString *result = [[NSMutableString alloc] init];
    switch (fileType) {
        case H_FILE:
        {
            [result appendFormat:@"\n\n@interface %@Request : AFHTTPSessionManager {\n", configDictionary[@"filename"]];
            [result appendFormat:@"}\n"];
            [result appendFormat:@"#pragma clang diagnostic push\n"];
            [result appendFormat:@"#pragma clang diagnostic ignored \"-Wdocumentation\"\n"];
            [result appendFormat:@"\n+ (instancetype _Nonnull)sharedClient;\n"];
            [result appendFormat:@"+ (void)resetClient;\n\n\n"];
        }
            break;
        case M_FILE:
        {
            [result appendFormat:@"\n@implementation %@Request\n", configDictionary[@"filename"]];
            [result appendFormat:@"#pragma clang diagnostic push\n"];
            [result appendFormat:@"#pragma clang diagnostic ignored \"-Wundeclared-selector\"\n"];
            [result appendFormat:@"\nstatic %@Request *_sharedClient;\n", configDictionary[@"filename"]];
            [result appendFormat:@"+ (instancetype _Nonnull)sharedClient {\n"];
            [result appendFormat:@"\tstatic dispatch_once_t onceToken;\n"];
            [result appendFormat:@"\tdispatch_once(&onceToken, ^{ \n"];
            [result appendFormat:@"\t\t[self resetClient];\n"];
            [result appendFormat:@"\t});\n"];
            [result appendFormat:@"\tif ([self respondsToSelector:@selector(configRequest:)]) {\n"];
            [result appendFormat:@"\t\t[self performSelector:@selector(configRequest:) withObject:_sharedClient];\n"];
            [result appendFormat:@"\t}\n"];
            [result appendFormat:@"\treturn _sharedClient;\n"];
            [result appendFormat:@"}\n\n"];
            
            [result appendFormat:@"+ (void)resetClient {\n"];
            [result appendFormat:@"\t_sharedClient = [[%@Request alloc] initWithBaseURL:[NSURL URLWithString:HOST_NAME]];\n", configDictionary[@"filename"]];
            [result appendFormat:@"\t_sharedClient.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];\n"];
            if ([configDictionary[@"response"] isEqualToString:@"xml"]) {
                [result appendFormat:@"\t_sharedClient.responseSerializer = [AFXMLParserResponseSerializer serializer];//申明返回的结果是json类型\n"];
            }
            else if ([configDictionary[@"response"] isEqualToString:@"json"]){
                [result appendFormat:@"\t_sharedClient.responseSerializer = [AFJSONResponseSerializer serializer];//申明返回的结果是json类型\n"];
            }
            if ([configDictionary.allKeys containsObject:@"content_type"]) {
                [result appendFormat:@"\t_sharedClient.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@\"%@\"];//如果报接受类型不一致请替换一致text/html或别的\n", configDictionary[@"content_type"]];
            }
            else {
                [result appendFormat:@"\t_sharedClient.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@\"text/html\"];//如果报接受类型不一致请替换一致text/html或别的\n"];
            }
            if ([configDictionary[@"request"] isEqualToString:@"json"]) {
                [result appendFormat:@"\t_sharedClient.requestSerializer = [AFJSONRequestSerializer serializer];//申明请求的数据是json类型\n"];
            }
            [result appendFormat:@"}\n\n\n"];
        }
            break;
            
        default:
            break;
    }
    
    return result;
}

/**
 * @brief  匹配出所有的Request类型
 * @prama  sourceString:需要匹配的字符串
 * @prama  fileType:[H_FILE:h文件  M_FILE: m文件]
 **/
+ (NSString *)messageFromSourceString:(NSString *)sourceString fileType:(FileType)fileType
{
    NSMutableString *result = [[NSMutableString alloc] init];
    NSString *regexRequest = @"request (get|post|upload|put|delete|iget|ipost|iupload|iput|idelete)(?:\\s+)(\\S+)(?:\\s+)(\\S+)(?:\\s*)\\{([\\s\\S]*?)\\}(?:\\s*?)";
    NSArray *requestList = [sourceString arrayOfCaptureComponentsMatchedByRegex:regexRequest];
    
    @autoreleasepool {
        for (NSArray *items in requestList) {
            NSString *requestType = @"get";
            requestType = [items objectAtIndex:1];
            NSString *interface = [items objectAtIndex:2];
            
            NSString *returnType = [items objectAtIndex:3];
            NSArray *contents = [[items objectAtIndex:4] componentsSeparatedByString:@"\n"];
            
            [result appendString:[self generationFileType:fileType baseURL:@"" requestType:requestType methodName:interface returnType:returnType contents:contents methodType:TYPE_NOTES]];
            [result appendString:[self generationFileType:fileType baseURL:@"" requestType:requestType methodName:interface returnType:returnType contents:contents methodType:TYPE_METHOD]];
            [result appendString:[self generationFileType:fileType baseURL:@"" requestType:requestType methodName:interface returnType:returnType contents:contents methodType:TYPE_REQUEST]];
            
        }
    }
    
    /// 匹配带路径的网络请求
    regexRequest = @"request (get|post|upload|put|delete|iget|ipost|iupload|iput|idelete)(?:\\s+)(\\S+)(?:\\s+)(\\S+)(?:\\s+)(\\S+)(?:\\s*)\\{([\\s\\S]*?)\\}(?:\\s*?)";
    requestList = [sourceString arrayOfCaptureComponentsMatchedByRegex:regexRequest];
    @autoreleasepool {
        for (NSArray *items in requestList) {
            NSString *requestType = @"get";
            requestType = [items objectAtIndex:1];
            NSString *interface = [items objectAtIndex:2];
            
            NSString *returnType = [items objectAtIndex:3];
            NSString *baseUrl = [items objectAtIndex:4];
            NSArray *contents = [[items objectAtIndex:5] componentsSeparatedByString:@"\n"];
            
            [result appendString:[self generationFileType:fileType baseURL:baseUrl requestType:requestType methodName:interface returnType:returnType contents:contents methodType:TYPE_NOTES]];
            [result appendString:[self generationFileType:fileType baseURL:baseUrl requestType:requestType methodName:interface returnType:returnType contents:contents methodType:TYPE_METHOD]];
            [result appendString:[self generationFileType:fileType baseURL:baseUrl requestType:requestType methodName:interface returnType:returnType contents:contents methodType:TYPE_REQUEST]];
            
        }
    }
    
    return result;
}

/**
 * @brief  生成方法名
 * @prama  fileType:[H_FILE:h文件  M_FILE: m文件]
 * @prama  baseURL 基础路径
 * @prama  requestType:接口类型 get | post | upload
 * @prama  interface:接口名称
 * @prama  returnType:返回类型
 * @prama  methodType:方法类型
 * @prama  contents:接口参数
 */
+ (NSString *)generationFileType:(FileType)fileType baseURL:(NSString *)baseURL requestType:(NSString *)requestType methodName:(NSString *)interface returnType:(NSString *)returnType contents:(NSArray *)contents methodType:(MethodType)methodType
{
    NSMutableString *result = [[NSMutableString alloc] init];
    
    NSMutableString *interfacename = (NSMutableString *)interface;
    NSString *regex = @"^(?:[\\s]*)(?:[\\s]*)(\\S+)(?:[\\s]*)((?:\\()\\S+(?:\\)))";
    NSArray *nameList = [[interface arrayOfCaptureComponentsMatchedByRegex:regex] firstObject];
    if (nameList.count >= 3) {
        interface = [nameList objectAtIndex:1];
        interfacename = [[NSMutableString alloc] initWithString:[nameList objectAtIndex:2]];
        [interfacename deleteCharactersInRange:[interfacename rangeOfString:@"("]];
        [interfacename deleteCharactersInRange:[interfacename rangeOfString:@")"]];
    }
    
    NSString *uploadKey = @"";
    // h m 文件中均需导入的
    switch (methodType) {
        case TYPE_NOTES:
        {
            [result appendFormat:@"/**\n"];
            [result appendFormat:@" * @brief %@\n", [[contents firstObject] stringByReplacingOccurrencesOfString:@"/" withString:@""]];
            [result appendString:[self allPramaFromContents:contents withType:methodType fileType:fileType]];
            [result appendFormat:@" **/\n"];
        }
            break;
            
        case TYPE_METHOD:
        {
            [result appendFormat:@"+(NSURLSessionDataTask * _Nonnull)%@RequestUrl:(NSString * _Nullable)baseurl", [interfacename stringByReplacingOccurrencesOfString:@"/" withString:@""]];
            
            //判断是否是上传接口  上传接口需要提取出来单独处理
            if ([requestType isEqualToString:@"upload"] || [requestType isEqualToString:@"iupload"]) {
                for (NSString *line in contents) {
                    NSString *regexLine = @"^(?:[\\s]*)(loadpath)(?:[\\s]*)(\\S+)(?:[\\s]*)(\\S+)(?:[\\s]*)=(?:[\\s]*)(\\S+)(?:[\\s]*);([\\S\\s]*)$";
                    NSArray *lineList = [line arrayOfCaptureComponentsMatchedByRegex:regexLine];
                    if (lineList.count == 0) {
                        continue;
                    }
                    NSArray *fields = [lineList firstObject];
                    if (fields.count < 6) {
                        continue;
                    }
                    
                    NSString *style = [fields objectAtIndex:1];
                    NSString *type = [fields objectAtIndex:2];
                    NSString *fieldname = [fields objectAtIndex:3];
                    NSMutableString *keyname = [fields objectAtIndex:3];
                    NSString *regex = @"^(?:[\\s]*)(?:[\\s]*)(\\S+)(?:[\\s]*)((?:\\()\\S+(?:\\)))";
                    NSArray *nameList = [[fieldname arrayOfCaptureComponentsMatchedByRegex:regex] firstObject];
                    if (nameList.count >= 3) {
                        fieldname = [nameList objectAtIndex:1];
                        keyname = [[NSMutableString alloc] initWithString:[nameList objectAtIndex:2]];
                        [keyname deleteCharactersInRange:[keyname rangeOfString:@"("]];
                        [keyname deleteCharactersInRange:[keyname rangeOfString:@")"]];
                    }
                    uploadKey = fieldname;
                    NSString *defaultValue = [fields objectAtIndex:4];
                    NSString *notes = [fields objectAtIndex:5];
                    
                    [result appendFormat:@" formDataBlock:(void(^ _Nullable)(id<AFMultipartFormData> _Nullable formData))formDataBlock"];
                }
            }
            else if ([requestType isEqualToString:@"get"] || [requestType isEqualToString:@"iget"]) {
            }
            else if ([requestType isEqualToString:@"post"] || [requestType isEqualToString:@"ipost"]) {
            } else if ([requestType isEqualToString:@"put"] || [requestType isEqualToString:@"iput"]) {
            } else if ([requestType isEqualToString:@"delete"] || [requestType isEqualToString:@"idelete"]) {
            }
            else {
                NSLog(@"ERROR -- 网络请求接口参数有误");
            }
            [result appendString:[self allPramaFromContents:contents withType:methodType fileType:fileType]];
            [result appendFormat:@" success:(void (^ _Nullable)(NSURLSessionDataTask * _Nonnull task, %@ * _Nullable result))success  failure:(void (^ _Nullable)(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error))failure;", returnType];
            
            
        }
            break;
        default:
            break;
    }
    
    
    //区分 h m 文件导入的
    switch (fileType) {
        case H_FILE:
        {
            switch (methodType) {
                case TYPE_REQUEST:
                {
                    [result appendFormat:@"\n\n"];
                }
                    break;
                    
                default:
                    break;
            }
        }
            break;
        case M_FILE:
        {
            switch (methodType) {
                case TYPE_REQUEST:
                {
                    NSString *processString = [requestType hasPrefix:@"i"]?@"//":@"";
                    
                    [result appendFormat:@"{\n"];
                    
                    [result appendFormat:@"\tvoid (^show)(void) = ^{\n"];
                    [result appendFormat:@"\t\t%@[SVProgressHUD showProgress:0];\n", processString];
                    [result appendFormat:@"\t\t[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;\n"];
                    [result appendFormat:@"\t};\n"];
                    [result appendFormat:@"\tYLT_MAIN(show);\n\n"];
                    
                    [result appendFormat:@"\tNSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:([@{@\"action\":@\"%@\"} baseParams])];\n", interfacename];
                    [result appendString:[self allPramaFromContents:contents withType:methodType fileType:fileType]];
                    
                    if ([requestType isEqualToString:@"get"] || [requestType isEqualToString:@"iget"]) {
                        [result appendFormat:@"\tNSURLSessionDataTask *op = [[%@Request sharedClient] GET:[[NSString stringWithFormat:@\"%%@/%@/%%@\", BASE_URL, baseurl] baseURL] parameters:([params uploadParams]) progress:^(NSProgress * _Nonnull uploadProgress) {\n\t\t%@[SVProgressHUD showProgress:((CGFloat)uploadProgress.completedUnitCount)/((CGFloat)uploadProgress.totalUnitCount)];\n\t} success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary* _Nullable result) {\n", configDictionary[@"filename"], baseURL, processString];
                    }
                    else if ([requestType isEqualToString:@"post"] || [requestType isEqualToString:@"ipost"]) {
                        [result appendFormat:@"\tNSURLSessionDataTask *op = [[%@Request sharedClient] POST:[[NSString stringWithFormat:@\"%%@/%@/%%@\", BASE_URL, baseurl] baseURL] parameters:([params uploadParams]) progress:^(NSProgress * _Nonnull uploadProgress) {\n\t\t%@[SVProgressHUD showProgress:((CGFloat)uploadProgress.completedUnitCount)/((CGFloat)uploadProgress.totalUnitCount)];\n\t} success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary* _Nullable result) {\n", configDictionary[@"filename"], baseURL, processString];
                    }
                    else if ([requestType isEqualToString:@"upload"] || [requestType isEqualToString:@"iupload"]){
                        [result appendFormat:@"\tNSURLSessionDataTask *op = [[%@Request sharedClient] POST:[[NSString stringWithFormat:@\"%%@/%@/%%@\", BASE_URL, baseurl] baseURL] parameters:([params uploadParams])  constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {\n", configDictionary[@"filename"], baseURL];
                        [result appendFormat:@"\t\tif (formDataBlock) {\n"];
                        [result appendFormat:@"\t\t\tformDataBlock(formData);\n"];
                        [result appendFormat:@"\t\t}\n"];
                        [result appendFormat:@"\t}\n"];
                        [result appendFormat:@"\tprogress:^(NSProgress * _Nonnull uploadProgress) {\n\t\t%@[SVProgressHUD showProgress:((CGFloat)uploadProgress.completedUnitCount)/((CGFloat)uploadProgress.totalUnitCount)];\n\t}", processString];
                        [result appendFormat:@" success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary* _Nullable result) {\n"];
                    }
                    else if ([requestType isEqualToString:@"put"] || [requestType isEqualToString:@"iput"]) {
                        [result appendFormat:@"\tNSURLSessionDataTask *op = [[%@Request sharedClient] PUT:[[NSString stringWithFormat:@\"%%@/%@/%%@\", BASE_URL, baseurl] baseURL] parameters:([params uploadParams]) success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary* _Nullable result) {\n", configDictionary[@"filename"], baseURL];
                    }
                    else if ([requestType isEqualToString:@"delete"] || [requestType isEqualToString:@"idelete"]) {
                        [result appendFormat:@"\tNSURLSessionDataTask *op = [[%@Request sharedClient] DELETE:[[NSString stringWithFormat:@\"%%@/%@/%%@\", BASE_URL, baseurl] baseURL] parameters:([params uploadParams]) success:^(NSURLSessionDataTask * _Nonnull task, NSDictionary* _Nullable result) {\n", configDictionary[@"filename"], baseURL];
                    }
                    
                    [result appendFormat:@"\t\t%@[SVProgressHUD dismiss];\n", processString];
                    [result appendString:@"\t\t[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;\n"];
                    [result appendFormat:@"\t\t%@ *info;\n", returnType];
                    if ([configDictionary[@"response"] isEqualToString:@"xml"]) {
                        [result appendString:@"\t\tresult = [[XMLDictionaryParser sharedInstance] dictionaryWithParser:result];\n"];
                    }
                    else if ([configDictionary[@"response"] isEqualToString:@"json"]){
                    }
                    [result appendString:@"\t\tresult = ([result responseParams]);\n"];
                    [result appendString:@"\t\tif (result && result.allKeys.count > 0) {\n"];
                    [result appendFormat:@"\t\t\tinfo = [%@ ylt_objectWithKeyValues:result];\n", returnType];
                    [result appendString:@"\t\t\tif (info) {\n"];
                    [result appendString:@"\t\t\t\tsuccess(task, info);\n"];
                    [result appendString:@"\t\t\t}\n"];
                    [result appendString:@"\t\t} else {\n"];
                    [result appendString:@"\t\t\tNSError *error = [NSError errorWithDomain:@\"Request\" code:9999 userInfo:@{@\"localizedDescription\":@\"数据为空\"}];\n"];
                    [result appendString:@"\t\t\tfailure(task, error);\n"];
                    [result appendString:@"\t\t}\n"];
                    [result appendString:@"\t} failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {\n"];
                    [result appendString:@"\t\tYLT_LogError(@\"%@\", task);\n"];
                    [result appendFormat:@"\t\t%@[SVProgressHUD dismiss];\n", processString];
                    [result appendString:@"\t\t[SVProgressHUD showErrorWithStatus:@\"网络异常\"];\n"];
                    [result appendString:@"\t\t[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;\n"];
                    [result appendFormat:@"\t\tfailure(task, error);\n"];
                    [result appendString:@"\t}];\n"];
                    [result appendString:@"\treturn op;\n"];
                    [result appendString:@"}\n\n\n"];
                }
                    break;
                    
                default:
                    break;
            }
        }
        default:
            break;
    }
    
    
    
    return result;
}

/**
 * @brief  request请求的所有参数
 * @prama  contents:参数列表
 * @prama  methodType:方法类型
 * @prama  fileType:[H_FILE:h文件  M_FILE: m文件]
 */
+ (NSString *)allPramaFromContents:(NSArray *)contents withType:(MethodType)methodType fileType:(FileType)fileType
{
    NSMutableString *result = [[NSMutableString alloc] init];
    for (int i = 0; i < contents.count; i++) {
        NSString *lineString = [contents objectAtIndex:i];
        NSString *regexLine = @"^(?:[\\s]*)(class|required|optional|repeated|upload)(?:[\\s]*)(\\S+)(?:[\\s]*)(\\S+)(?:[\\s]*)=(?:[\\s]*)(\\S+)(?:[\\s]*);([\\S\\s]*)$";
        NSArray *lineList = [lineString arrayOfCaptureComponentsMatchedByRegex:regexLine];
        
        if (lineList.count == 0) {
            continue;
        }
        NSArray *fields = [lineList firstObject];
        if (fields.count < 6) {
            continue;
        }
        NSString *style = [fields objectAtIndex:1];
        NSString *type = [fields objectAtIndex:2];
        NSString *fieldname = [fields objectAtIndex:3];
        NSMutableString *keyname = [fields objectAtIndex:3];
        NSString *regex = @"^(?:[\\s]*)(?:[\\s]*)(\\S+)(?:[\\s]*)((?:\\()\\S+(?:\\)))";
        NSArray *nameList = [[fieldname arrayOfCaptureComponentsMatchedByRegex:regex] firstObject];
        if (nameList.count >= 3) {
            fieldname = [nameList objectAtIndex:1];
            keyname = [[NSMutableString alloc] initWithString:[nameList objectAtIndex:2]];
            [keyname deleteCharactersInRange:[keyname rangeOfString:@"("]];
            [keyname deleteCharactersInRange:[keyname rangeOfString:@")"]];
        }
        NSString *defaultValue = [fields objectAtIndex:4];
        NSString *notes = [fields objectAtIndex:5];
        notes = [notes stringByReplacingOccurrencesOfString:@"/" withString:@""];
        
        //h m 文件都需要导入的文件
        switch (methodType) {
            case TYPE_NOTES:
            {
                [result appendFormat:@" * @prama %@:%@\n", fieldname, notes];
            }
                break;
                
            case TYPE_METHOD:
            {
                if ([style isEqualToString:@"repeated"]) {
                    if ([[Utils modelTypeConvertDictionary].allKeys containsObject:[type lowercaseString]]) {
                        [result appendFormat:@" %@:(NSArray<%@> * _Nonnull)%@", fieldname, [Utils modelTypeConvertDictionary][[type lowercaseString]], fieldname];
                    } else {
                        [result appendFormat:@" %@:(NSArray<%@ *> * _Nonnull)%@", fieldname, type, fieldname];
                    }
                }
                else if ([style isEqualToString:@"class"]) {
                    [result appendFormat:@" %@:(%@ *)%@", fieldname, type, fieldname];
                }
                else if ([[Utils modelTypeConvertDictionary].allKeys containsObject:[type lowercaseString]]){
                    if ([[Utils modelTypeConvertDictionary][[type lowercaseString]] rangeOfString:@"*"].location == NSNotFound) {
                        [result appendFormat:@" %@:(%@)%@", fieldname, [Utils modelTypeConvertDictionary][[type lowercaseString]], fieldname];
                    } else {
                        [result appendFormat:@" %@:(%@ _Nullable)%@", fieldname, [Utils modelTypeConvertDictionary][[type lowercaseString]], fieldname];
                    }
                }
                else {
                    //首先 区分开枚举类型与数据类型   所有的枚举类型  使用整型替代
                    [result appendFormat:@" %@:(%@ * _Nullable)%@", fieldname, type, fieldname];
                }
            }
                break;
                
            case TYPE_REQUEST:
            {
            }
                break;
                
            default:
                break;
        }
        
        switch (fileType) {
            case H_FILE:
            {
                
            }
                break;
            case M_FILE:
            {
                switch (methodType) {
                    case TYPE_REQUEST:
                    {
                        if ([style isEqualToString:@"repeated"]) {
                            [result appendFormat:@"\t[params setObj:%@ forKey:@\"%@\"];\n", fieldname, keyname];
                        }
                        else if ([style isEqualToString:@"class"]) {
                            [result appendFormat:@"\tif ([%@ respondsToSelector:@selector(dictionaryValue)] && [[%@ performSelector:@selector(dictionaryValue)] isKindOfClass:[NSDictionary class]]) {\n", fieldname, fieldname];
                            [result appendFormat:@"\t\t[params addEntriesFromDictionary:[%@ performSelector:@selector(dictionaryValue)]];\n", fieldname];
                            [result appendFormat:@"\t} else {\n"];
                            [result appendFormat:@"\t\t[params setObj:%@ forKey:@\"%@\"];\n", fieldname, keyname];
                            [result appendFormat:@"\t}\n"];
                        }
                        else {
                            if (IS_BASE_TYPE(type) || [enumList containsObject:type]) {
                                if ([[type lowercaseString] isEqualToString:@"int"] || [[type lowercaseString] isEqualToString:@"short"] || [enumList containsObject:type]) {
                                    [result appendFormat:@"\t[params setObj:[NSNumber numberWithInteger:%@] forKey:@\"%@\"];\n", fieldname, keyname];
                                }
                                else {
                                    [result appendFormat:@"\t[params setObj:[NSNumber numberWith%@:%@] forKey:@\"%@\"];\n", [NSString stringWithFormat:@"%@%@", [[type substringToIndex:1] uppercaseString], [type substringFromIndex:1]], fieldname, keyname];
                                }
                            }
                            else if ([type isEqualToString:@"string"] || [NSClassFromString(type) isKindOfClass:[NSObject class]]){
                                [result appendFormat:@"\t[params setObj:%@ forKey:@\"%@\"];\n", fieldname, keyname];
                            }
                            else {
#warning 非简单数据类型的处理 包含枚举类型和model类型
                                [result appendFormat:@"\tif ([%@ respondsToSelector:@selector(dictionaryValue)] && [[%@ performSelector:@selector(dictionaryValue)] isKindOfClass:[NSDictionary class]]) {\n", fieldname, fieldname];
                                [result appendFormat:@"\t\t[params addEntriesFromDictionary:[%@ performSelector:@selector(dictionaryValue)]];\n", fieldname];
                                [result appendFormat:@"\t} else {\n"];
                                [result appendFormat:@"\t\t[params setObj:%@ forKey:@\"%@\"];\n", fieldname, keyname];
                                [result appendFormat:@"\t}\n"];
//                                [result appendFormat:@"\t[params addEntriesFromDictionary:[%@ dictionaryValue]];\n", fieldname];
                            }
                        }
                    }
                        break;
                        
                    default:
                        break;
                }
            }
                break;
                
            default:
                break;
        }
        
    }
    
    
    return result;
}

@end


















