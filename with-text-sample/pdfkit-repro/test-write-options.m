#import <Foundation/Foundation.h>
#import <PDFKit/PDFKit.h>

static void analyze(NSString *path) {
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSString *text = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    NSUInteger s4 = 0, p1 = 0;
    NSRange r = NSMakeRange(0, text.length);
    while ((r = [text rangeOfString:@"ShadingType 4" options:0 range:r]).location != NSNotFound) { s4++; r.location++; r.length--; }
    r = NSMakeRange(0, text.length);
    while ((r = [text rangeOfString:@"PatternType 1" options:0 range:r]).location != NSNotFound) { p1++; r.location++; r.length--; }
    printf("%s  ver=%.8s  S4=%4lu  P1=%4lu  bytes=%lu\n",
           path.lastPathComponent.UTF8String, data.bytes, s4, p1, (unsigned long)data.length);
}

static BOOL writeDoc(PDFDocument *doc, NSString *path, NSDictionary *options, BOOL useData) {
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    if (useData) {
        NSData *data = options ? [doc dataRepresentationWithOptions:options] : [doc dataRepresentation];
        if (!data) return NO;
        return [data writeToFile:path atomically:YES];
    }
    return options ? [doc writeToURL:[NSURL fileURLWithPath:path] withOptions:options]
                   : [doc writeToURL:[NSURL fileURLWithPath:path]];
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 3) { fprintf(stderr, "usage: %s INPUT.pdf OUTDIR\n", argv[0]); return 1; }
        NSString *input = @(argv[1]);
        NSString *outDir = @(argv[2]);
        PDFDocument *doc = [[PDFDocument alloc] initWithURL:[NSURL fileURLWithPath:input]];
        if (!doc) { fprintf(stderr, "cannot open input\n"); return 1; }
        printf("input  major=%ld minor=%ld\n", (long)doc.majorVersion, (long)doc.minorVersion);
        analyze(input);

        NSArray<NSDictionary *> *cases = @[
            @{@"name": @"write-default", @"options": [NSNull null], @"data": @NO},
            @{@"name": @"dataRepresentation", @"options": [NSNull null], @"data": @YES},
            @{@"name": @"burnInAnnotations", @"options": @{PDFDocumentBurnInAnnotationsOption: @YES}, @"data": @NO},
            @{@"name": @"saveWithCorePDFLayout", @"options": @{@"SaveWithCorePDFLayout": @YES}, @"data": @NO},
            @{@"name": @"useAppendMode", @"options": @{@"UseAppendMode": @YES}, @"data": @NO},
            @{@"name": @"corepdf-plus-append", @"options": @{@"SaveWithCorePDFLayout": @YES, @"UseAppendMode": @YES}, @"data": @NO},
        ];

        for (NSDictionary *c in cases) {
            NSString *name = c[@"name"];
            NSString *out = [outDir stringByAppendingPathComponent:[name stringByAppendingString:@".pdf"]];
            NSDictionary *opts = c[@"options"] == [NSNull null] ? nil : c[@"options"];
            BOOL useData = [c[@"data"] boolValue];
            if (!writeDoc(doc, out, opts, useData)) {
                printf("%s: FAILED\n", name.UTF8String);
                continue;
            }
            analyze(out);
        }
    }
    return 0;
}