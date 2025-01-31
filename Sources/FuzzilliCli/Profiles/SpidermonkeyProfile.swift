// Copyright 2019 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Fuzzilli

fileprivate let ForceSpidermonkeyIonGenerator = CodeGenerator("ForceSpidermonkeyIonGenerator", input: .function()) { b, f in
   guard let arguments = b.randCallArguments(for: f) else { return }
    
    let start = b.loadInt(0)
    let end = b.loadInt(100)
    let step = b.loadInt(1)
    b.forLoop(start, .lessThan, end, .Add, step) { _ in
        b.callFunction(f, withArgs: arguments)
    }
}

let spidermonkeyProfile = Profile(
    processArguments: [
        "--no-threads",
        "--cpu-count=1",
        "--ion-offthread-compile=off",
        "--baseline-warmup-threshold=10",
        "--ion-warmup-threshold=50",
        "--ion-check-range-analysis",
        "--ion-extra-checks",
        "--fuzzing-safe",
        "--reprl",
    ],

    processEnv: ["UBSAN_OPTIONS": "handle_segv=0"],

    codePrefix: """
                function classOf(object) {
                   var string = Object.prototype.toString.call(object);
                   return string.substring(8, string.length - 1);
                }

                function deepObjectEquals(a, b) {
                  var aProps = Object.keys(a);
                  aProps.sort();
                  var bProps = Object.keys(b);
                  bProps.sort();
                  if (!deepEquals(aProps, bProps)) {
                    return false;
                  }
                  for (var i = 0; i < aProps.length; i++) {
                    if (!deepEquals(a[aProps[i]], b[aProps[i]])) {
                      return false;
                    }
                  }
                  return true;
                }

                function deepEquals(a, b) {
                  if (a === b) {
                    if (a === 0) return (1 / a) === (1 / b);
                    return true;
                  }
                  if (typeof a != typeof b) return false;
                  if (typeof a == 'number') return (isNaN(a) && isNaN(b)) || (a===b);
                  if (typeof a !== 'object' && typeof a !== 'function' && typeof a !== 'symbol') return false;
                  var objectClass = classOf(a);
                  if (objectClass === 'Array') {
                    if (a.length != b.length) {
                      return false;
                    }
                    for (var i = 0; i < a.length; i++) {
                      if (!deepEquals(a[i], b[i])) return false;
                    }
                    return true;
                  }                
                  if (objectClass !== classOf(b)) return false;
                  if (objectClass === 'RegExp') {
                    return (a.toString() === b.toString());
                  }
                  if (objectClass === 'Function') return true;
                  
                  if (objectClass == 'String' || objectClass == 'Number' ||
                      objectClass == 'Boolean' || objectClass == 'Date') {
                    if (a.valueOf() !== b.valueOf()) return false;
                  }
                  return deepObjectEquals(a, b);
                }

                function opt(opt_param){
                """,

    codeSuffix: """
                }
                let jit_a0 = opt(true);
                let jit_a0_0 = opt(false);
                for(let i=0;i<0x50;i++){opt(false);}
                let jit_a2 = opt(true);
                if (jit_a0 === undefined && jit_a2 === undefined) {
                    opt(true);
                } else {
                    if (jit_a0_0===jit_a0 && !deepEquals(jit_a0, jit_a2)) {
                        fuzzilli('FUZZILLI_CRASH', 0);
                    }
                }
                """,

    ecmaVersion: ECMAScriptVersion.es6,

    crashTests: ["fuzzilli('FUZZILLI_CRASH', 0)", "fuzzilli('FUZZILLI_CRASH', 1)", "fuzzilli('FUZZILLI_CRASH', 2)"],

    additionalCodeGenerators: WeightedList<CodeGenerator>([
//        (ForceSpidermonkeyIonGenerator, 10),
    ]),

    additionalProgramTemplates: WeightedList<ProgramTemplate>([]),

    disabledCodeGenerators: [],

    additionalBuiltins: [
        :
//        "gc"            : .function([] => .undefined),
        // "enqueueJob"    : .function([.function()] => .undefined),
        // "drainJobQueue" : .function([] => .undefined),
        // "bailout"       : .function([] => .undefined),
        // "placeholder"   : .function([] => .undefined),

    ]
)
