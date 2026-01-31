var __defProp = Object.defineProperty;
var __getOwnPropNames = Object.getOwnPropertyNames;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });
var __esm = (fn, res) => function __init() {
  return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
};
var __export = (target, all) => {
  for (var name in all)
    __defProp(target, name, { get: all[name], enumerable: true });
};

// wrangler-modules-watch:wrangler:modules-watch
var init_wrangler_modules_watch = __esm({
  "wrangler-modules-watch:wrangler:modules-watch"() {
    init_modules_watch_stub();
  }
});

// ../../../../.npm/_npx/32026684e21afda6/node_modules/wrangler/templates/modules-watch-stub.js
var init_modules_watch_stub = __esm({
  "../../../../.npm/_npx/32026684e21afda6/node_modules/wrangler/templates/modules-watch-stub.js"() {
    init_wrangler_modules_watch();
  }
});

// _build/js/release/build/worker/worker.js
var worker_exports = {};
__export(worker_exports, {
  get_fetch_handler: () => f4ah6o$blog$46$mbt$worker$$get_fetch_handler
});
function $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
function $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$Bool(param0) {
  this._0 = param0;
}
function $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$ClassList(param0) {
  this._0 = param0;
}
function $panic() {
  throw new $PanicError();
}
function $bound_check(arr, index) {
  if (index < 0 || index >= arr.length) throw new Error("Index out of bounds");
}
function $compare_int(a, b) {
  return (a >= b) - (a <= b);
}
function Result$Err$0$(param0) {
  this._0 = param0;
}
function Result$Ok$0$(param0) {
  this._0 = param0;
}
function $make_array_len_and_init(a, b) {
  const arr = new Array(a);
  arr.fill(b);
  return arr;
}
function $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Element(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
function $64$f4ah6o$47$tmpx$47$tmpx$46$Node$VoidElement(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
function $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(param0) {
  this._0 = param0;
}
function $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Raw(param0) {
  this._0 = param0;
}
function $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Fragment(param0) {
  this._0 = param0;
}
function $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Custom(param0) {
  this._0 = param0;
}
function Result$Err$1$(param0) {
  this._0 = param0;
}
function Result$Ok$1$(param0) {
  this._0 = param0;
}
function moonbitlang$core$abort$$abort$2$(msg) {
  $panic();
}
function moonbitlang$core$builtin$$abort$2$(string, loc) {
  moonbitlang$core$abort$$abort$2$(`${string}
  at ${moonbitlang$core$builtin$$Show$to_string$3$(loc)}
`);
}
function moonbitlang$core$builtin$$StringBuilder$new$46$inner(size_hint) {
  return { val: "" };
}
function moonbitlang$core$builtin$$Logger$write_char$0$(self, ch) {
  const _bind = self;
  _bind.val = `${_bind.val}${String.fromCodePoint(ch)}`;
}
function moonbitlang$core$uint16$$UInt16$is_leading_surrogate(self) {
  return moonbitlang$core$builtin$$Compare$op_ge$4$(self, 55296) && moonbitlang$core$builtin$$Compare$op_le$4$(self, 56319);
}
function moonbitlang$core$uint16$$UInt16$is_trailing_surrogate(self) {
  return moonbitlang$core$builtin$$Compare$op_ge$4$(self, 56320) && moonbitlang$core$builtin$$Compare$op_le$4$(self, 57343);
}
function moonbitlang$core$builtin$$code_point_of_surrogate_pair(leading, trailing) {
  return (((Math.imul(leading - 55296 | 0, 1024) | 0) + trailing | 0) - 56320 | 0) + 65536 | 0;
}
function moonbitlang$core$array$$Array$at$5$(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function moonbitlang$core$builtin$$SourceLocRepr$parse(repr) {
  const _bind = { str: repr, start: 0, end: repr.length };
  const _data = _bind.str;
  const _start = _bind.start;
  const _end = _start + (_bind.end - _bind.start | 0) | 0;
  let _cursor = _start;
  let accept_state = -1;
  let match_end = -1;
  let match_tag_saver_0 = -1;
  let match_tag_saver_1 = -1;
  let match_tag_saver_2 = -1;
  let match_tag_saver_3 = -1;
  let match_tag_saver_4 = -1;
  let tag_0 = -1;
  let tag_1 = -1;
  let tag_1_1 = -1;
  let tag_1_2 = -1;
  let tag_3 = -1;
  let tag_2 = -1;
  let tag_2_1 = -1;
  let tag_4 = -1;
  _L: {
    let join_dispatch_19;
    _L$2: {
      if (_cursor < _end) {
        const _p = _cursor;
        const next_char = _data.charCodeAt(_p);
        _cursor = _cursor + 1 | 0;
        if (next_char < 65) {
          if (next_char < 64) {
            break _L;
          } else {
            while (true) {
              tag_0 = _cursor;
              if (_cursor < _end) {
                _L$3: {
                  const _p$2 = _cursor;
                  const next_char$2 = _data.charCodeAt(_p$2);
                  _cursor = _cursor + 1 | 0;
                  if (next_char$2 < 55296) {
                    if (next_char$2 < 58) {
                      break _L$3;
                    } else {
                      if (next_char$2 > 58) {
                        break _L$3;
                      } else {
                        if (_cursor < _end) {
                          _L$4: {
                            const _p$3 = _cursor;
                            const next_char$3 = _data.charCodeAt(_p$3);
                            _cursor = _cursor + 1 | 0;
                            if (next_char$3 < 56319) {
                              if (next_char$3 < 55296) {
                                break _L$4;
                              } else {
                                join_dispatch_19 = 7;
                                break _L$2;
                              }
                            } else {
                              if (next_char$3 > 56319) {
                                if (next_char$3 < 65536) {
                                  break _L$4;
                                } else {
                                  break _L;
                                }
                              } else {
                                join_dispatch_19 = 8;
                                break _L$2;
                              }
                            }
                          }
                          join_dispatch_19 = 0;
                          break _L$2;
                        } else {
                          break _L;
                        }
                      }
                    }
                  } else {
                    if (next_char$2 > 56318) {
                      if (next_char$2 < 57344) {
                        if (_cursor < _end) {
                          const _p$3 = _cursor;
                          const next_char$3 = _data.charCodeAt(_p$3);
                          _cursor = _cursor + 1 | 0;
                          if (next_char$3 < 56320) {
                            break _L;
                          } else {
                            if (next_char$3 > 57343) {
                              break _L;
                            } else {
                              continue;
                            }
                          }
                        } else {
                          break _L;
                        }
                      } else {
                        if (next_char$2 > 65535) {
                          break _L;
                        } else {
                          break _L$3;
                        }
                      }
                    } else {
                      if (_cursor < _end) {
                        const _p$3 = _cursor;
                        const next_char$3 = _data.charCodeAt(_p$3);
                        _cursor = _cursor + 1 | 0;
                        if (next_char$3 < 56320) {
                          break _L;
                        } else {
                          if (next_char$3 > 65535) {
                            break _L;
                          } else {
                            continue;
                          }
                        }
                      } else {
                        break _L;
                      }
                    }
                  }
                }
                continue;
              } else {
                break _L;
              }
            }
          }
        } else {
          break _L;
        }
      } else {
        break _L;
      }
    }
    let _tmp = join_dispatch_19;
    _L$3: while (true) {
      const dispatch_19 = _tmp;
      _L$4: {
        _L$5: {
          switch (dispatch_19) {
            case 3: {
              tag_1_2 = tag_1_1;
              tag_1_1 = tag_1;
              tag_1 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        tag_1 = _cursor;
                        tag_2_1 = tag_2;
                        tag_2 = _cursor;
                        tag_3 = _cursor;
                        if (_cursor < _end) {
                          _L$7: {
                            const _p$2 = _cursor;
                            const next_char$2 = _data.charCodeAt(_p$2);
                            _cursor = _cursor + 1 | 0;
                            if (next_char$2 < 59) {
                              if (next_char$2 < 46) {
                                if (next_char$2 < 45) {
                                  break _L$7;
                                } else {
                                  break _L$4;
                                }
                              } else {
                                if (next_char$2 > 47) {
                                  if (next_char$2 < 58) {
                                    _tmp = 6;
                                    continue _L$3;
                                  } else {
                                    _tmp = 3;
                                    continue _L$3;
                                  }
                                } else {
                                  break _L$7;
                                }
                              }
                            } else {
                              if (next_char$2 > 55295) {
                                if (next_char$2 < 57344) {
                                  if (next_char$2 < 56319) {
                                    _tmp = 7;
                                    continue _L$3;
                                  } else {
                                    _tmp = 8;
                                    continue _L$3;
                                  }
                                } else {
                                  if (next_char$2 > 65535) {
                                    break _L;
                                  } else {
                                    break _L$7;
                                  }
                                }
                              } else {
                                break _L$7;
                              }
                            }
                          }
                          _tmp = 0;
                          continue _L$3;
                        } else {
                          break _L;
                        }
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 1;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 2: {
              tag_1 = _cursor;
              tag_2 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 2;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 3;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 0: {
              tag_1 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      break _L$6;
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 1;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 8: {
              if (_cursor < _end) {
                const _p = _cursor;
                const next_char = _data.charCodeAt(_p);
                _cursor = _cursor + 1 | 0;
                if (next_char < 56320) {
                  break _L;
                } else {
                  if (next_char > 57343) {
                    break _L;
                  } else {
                    _tmp = 0;
                    continue _L$3;
                  }
                }
              } else {
                break _L;
              }
            }
            case 4: {
              tag_1 = _cursor;
              tag_4 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 4;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        tag_1_2 = tag_1_1;
                        tag_1_1 = tag_1;
                        tag_1 = _cursor;
                        if (_cursor < _end) {
                          _L$7: {
                            const _p$2 = _cursor;
                            const next_char$2 = _data.charCodeAt(_p$2);
                            _cursor = _cursor + 1 | 0;
                            if (next_char$2 < 55296) {
                              if (next_char$2 < 58) {
                                if (next_char$2 < 48) {
                                  break _L$7;
                                } else {
                                  tag_1 = _cursor;
                                  tag_2_1 = tag_2;
                                  tag_2 = _cursor;
                                  if (_cursor < _end) {
                                    _L$8: {
                                      const _p$3 = _cursor;
                                      const next_char$3 = _data.charCodeAt(_p$3);
                                      _cursor = _cursor + 1 | 0;
                                      if (next_char$3 < 55296) {
                                        if (next_char$3 < 58) {
                                          if (next_char$3 < 48) {
                                            break _L$8;
                                          } else {
                                            _tmp = 5;
                                            continue _L$3;
                                          }
                                        } else {
                                          if (next_char$3 > 58) {
                                            break _L$8;
                                          } else {
                                            _tmp = 3;
                                            continue _L$3;
                                          }
                                        }
                                      } else {
                                        if (next_char$3 > 56318) {
                                          if (next_char$3 < 57344) {
                                            _tmp = 8;
                                            continue _L$3;
                                          } else {
                                            if (next_char$3 > 65535) {
                                              break _L;
                                            } else {
                                              break _L$8;
                                            }
                                          }
                                        } else {
                                          _tmp = 7;
                                          continue _L$3;
                                        }
                                      }
                                    }
                                    _tmp = 0;
                                    continue _L$3;
                                  } else {
                                    break _L$5;
                                  }
                                }
                              } else {
                                if (next_char$2 > 58) {
                                  break _L$7;
                                } else {
                                  _tmp = 1;
                                  continue _L$3;
                                }
                              }
                            } else {
                              if (next_char$2 > 56318) {
                                if (next_char$2 < 57344) {
                                  _tmp = 8;
                                  continue _L$3;
                                } else {
                                  if (next_char$2 > 65535) {
                                    break _L;
                                  } else {
                                    break _L$7;
                                  }
                                }
                              } else {
                                _tmp = 7;
                                continue _L$3;
                              }
                            }
                          }
                          _tmp = 0;
                          continue _L$3;
                        } else {
                          break _L;
                        }
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 5: {
              tag_1 = _cursor;
              tag_2 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 5;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 3;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L$5;
              }
            }
            case 6: {
              tag_1 = _cursor;
              tag_2 = _cursor;
              tag_3 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 59) {
                    if (next_char < 46) {
                      if (next_char < 45) {
                        break _L$6;
                      } else {
                        break _L$4;
                      }
                    } else {
                      if (next_char > 47) {
                        if (next_char < 58) {
                          _tmp = 6;
                          continue _L$3;
                        } else {
                          _tmp = 3;
                          continue _L$3;
                        }
                      } else {
                        break _L$6;
                      }
                    }
                  } else {
                    if (next_char > 55295) {
                      if (next_char < 57344) {
                        if (next_char < 56319) {
                          _tmp = 7;
                          continue _L$3;
                        } else {
                          _tmp = 8;
                          continue _L$3;
                        }
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      break _L$6;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            case 7: {
              if (_cursor < _end) {
                const _p = _cursor;
                const next_char = _data.charCodeAt(_p);
                _cursor = _cursor + 1 | 0;
                if (next_char < 56320) {
                  break _L;
                } else {
                  if (next_char > 65535) {
                    break _L;
                  } else {
                    _tmp = 0;
                    continue _L$3;
                  }
                }
              } else {
                break _L;
              }
            }
            case 1: {
              tag_1_1 = tag_1;
              tag_1 = _cursor;
              if (_cursor < _end) {
                _L$6: {
                  const _p = _cursor;
                  const next_char = _data.charCodeAt(_p);
                  _cursor = _cursor + 1 | 0;
                  if (next_char < 55296) {
                    if (next_char < 58) {
                      if (next_char < 48) {
                        break _L$6;
                      } else {
                        _tmp = 2;
                        continue _L$3;
                      }
                    } else {
                      if (next_char > 58) {
                        break _L$6;
                      } else {
                        _tmp = 1;
                        continue _L$3;
                      }
                    }
                  } else {
                    if (next_char > 56318) {
                      if (next_char < 57344) {
                        _tmp = 8;
                        continue _L$3;
                      } else {
                        if (next_char > 65535) {
                          break _L;
                        } else {
                          break _L$6;
                        }
                      }
                    } else {
                      _tmp = 7;
                      continue _L$3;
                    }
                  }
                }
                _tmp = 0;
                continue _L$3;
              } else {
                break _L;
              }
            }
            default: {
              break _L;
            }
          }
        }
        tag_1 = tag_1_2;
        tag_2 = tag_2_1;
        match_tag_saver_0 = tag_0;
        match_tag_saver_1 = tag_1;
        match_tag_saver_2 = tag_2;
        match_tag_saver_3 = tag_3;
        match_tag_saver_4 = tag_4;
        accept_state = 0;
        match_end = _cursor;
        break _L;
      }
      tag_1_1 = tag_1_2;
      tag_1 = _cursor;
      tag_2 = tag_2_1;
      if (_cursor < _end) {
        _L$5: {
          const _p = _cursor;
          const next_char = _data.charCodeAt(_p);
          _cursor = _cursor + 1 | 0;
          if (next_char < 55296) {
            if (next_char < 58) {
              if (next_char < 48) {
                break _L$5;
              } else {
                _tmp = 4;
                continue;
              }
            } else {
              if (next_char > 58) {
                break _L$5;
              } else {
                _tmp = 1;
                continue;
              }
            }
          } else {
            if (next_char > 56318) {
              if (next_char < 57344) {
                _tmp = 8;
                continue;
              } else {
                if (next_char > 65535) {
                  break _L;
                } else {
                  break _L$5;
                }
              }
            } else {
              _tmp = 7;
              continue;
            }
          }
        }
        _tmp = 0;
        continue;
      } else {
        break _L;
      }
    }
  }
  if (accept_state === 0) {
    let start_line;
    let _try_err;
    _L$2: {
      _L$3: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_1 + 1 | 0, match_tag_saver_2);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          start_line = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err = _tmp;
          break _L$3;
        }
        break _L$2;
      }
      start_line = $panic();
    }
    let start_column;
    let _try_err$2;
    _L$3: {
      _L$4: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_2 + 1 | 0, match_tag_saver_3);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          start_column = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$2 = _tmp;
          break _L$4;
        }
        break _L$3;
      }
      start_column = $panic();
    }
    let pkg;
    let _try_err$3;
    _L$4: {
      _L$5: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, _start + 1 | 0, match_tag_saver_0);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          pkg = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$3 = _tmp;
          break _L$5;
        }
        break _L$4;
      }
      pkg = $panic();
    }
    let filename;
    let _try_err$4;
    _L$5: {
      _L$6: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_0 + 1 | 0, match_tag_saver_1);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          filename = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$4 = _tmp;
          break _L$6;
        }
        break _L$5;
      }
      filename = $panic();
    }
    let end_line;
    let _try_err$5;
    _L$6: {
      _L$7: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_3 + 1 | 0, match_tag_saver_4);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          end_line = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$5 = _tmp;
          break _L$7;
        }
        break _L$6;
      }
      end_line = $panic();
    }
    let end_column;
    let _try_err$6;
    _L$7: {
      _L$8: {
        const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_4 + 1 | 0, match_end);
        if (_bind$2.$tag === 1) {
          const _ok = _bind$2;
          end_column = _ok._0;
        } else {
          const _err = _bind$2;
          const _tmp = _err._0;
          _try_err$6 = _tmp;
          break _L$8;
        }
        break _L$7;
      }
      end_column = $panic();
    }
    return { pkg, filename, start_line, start_column, end_line, end_column };
  } else {
    return $panic();
  }
}
function moonbitlang$core$builtin$$Logger$write_string$0$(self, str) {
  const _bind = self;
  _bind.val = `${_bind.val}${str}`;
}
function moonbitlang$core$builtin$$Compare$op_le$4$(x, y) {
  return $compare_int(x, y) <= 0;
}
function moonbitlang$core$builtin$$Compare$op_ge$4$(x, y) {
  return $compare_int(x, y) >= 0;
}
function moonbitlang$core$string$$String$sub$46$inner(self, start, end) {
  const len = self.length;
  let end$2;
  if (end === void 0) {
    end$2 = len;
  } else {
    const _Some = end;
    const _end = _Some;
    end$2 = _end < 0 ? len + _end | 0 : _end;
  }
  const start$2 = start < 0 ? len + start | 0 : start;
  if (start$2 >= 0 && (start$2 <= end$2 && end$2 <= len)) {
    if (start$2 < len && moonbitlang$core$uint16$$UInt16$is_trailing_surrogate(self.charCodeAt(start$2))) {
      return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex);
    }
    if (end$2 < len && moonbitlang$core$uint16$$UInt16$is_trailing_surrogate(self.charCodeAt(end$2))) {
      return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex);
    }
    return new Result$Ok$0$({ str: self, start: start$2, end: end$2 });
  } else {
    return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$IndexOutOfBounds);
  }
}
function moonbitlang$core$string$$String$sub(self, start$46$opt, end) {
  let start;
  if (start$46$opt === void 0) {
    start = 0;
  } else {
    const _Some = start$46$opt;
    start = _Some;
  }
  return moonbitlang$core$string$$String$sub$46$inner(self, start, end);
}
function moonbitlang$core$builtin$$Logger$write_substring$1$(self, value, start, len) {
  let _tmp;
  let _try_err;
  _L: {
    _L$2: {
      const _bind = moonbitlang$core$string$$String$sub$46$inner(value, start, start + len | 0);
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _tmp = _ok._0;
      } else {
        const _err = _bind;
        const _tmp$2 = _err._0;
        _try_err = _tmp$2;
        break _L$2;
      }
      break _L;
    }
    _tmp = $panic();
  }
  moonbitlang$core$builtin$$Logger$write_view$0$(self, _tmp);
}
function moonbitlang$core$builtin$$Show$to_string$3$(self) {
  const logger = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  moonbitlang$core$builtin$$Show$output$6$(self, { self: logger, method_table: $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger });
  return logger.val;
}
function moonbitlang$core$int$$Int$to_string$46$inner(self, radix) {
  return moonbitlang$core$builtin$$int_to_string_js(self, radix);
}
function moonbitlang$core$builtin$$Show$to_string$7$(self) {
  return self.str.substring(self.start, self.end);
}
function moonbitlang$core$string$$String$from_array(chars) {
  const buf = moonbitlang$core$builtin$$StringBuilder$new$46$inner(Math.imul(chars.end - chars.start | 0, 4) | 0);
  const _len = chars.end - chars.start | 0;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const c = chars.buf[chars.start + _i | 0];
      moonbitlang$core$builtin$$Logger$write_char$0$(buf, c);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return buf.val;
}
function moonbitlang$core$string$$String$char_length_eq$46$inner(self, len, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === void 0) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  let _tmp = start_offset;
  let _tmp$2 = 0;
  while (true) {
    const index = _tmp;
    const count = _tmp$2;
    if (index < end_offset$2 && count < len) {
      const c1 = self.charCodeAt(index);
      if (moonbitlang$core$uint16$$UInt16$is_leading_surrogate(c1) && (index + 1 | 0) < end_offset$2) {
        const _tmp$3 = index + 1 | 0;
        const c2 = self.charCodeAt(_tmp$3);
        if (moonbitlang$core$uint16$$UInt16$is_trailing_surrogate(c2)) {
          _tmp = index + 2 | 0;
          _tmp$2 = count + 1 | 0;
          continue;
        } else {
          moonbitlang$core$builtin$$abort$2$("invalid surrogate pair", "@moonbitlang/core/builtin:string.mbt:424:9-424:40");
        }
      }
      _tmp = index + 1 | 0;
      _tmp$2 = count + 1 | 0;
      continue;
    } else {
      return count === len && index === end_offset$2;
    }
  }
}
function moonbitlang$core$builtin$$Logger$write_view$0$(self, str) {
  const _bind = self;
  _bind.val = `${_bind.val}${moonbitlang$core$builtin$$Show$to_string$7$(str)}`;
}
function moonbitlang$core$builtin$$boyer_moore_horspool_find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const skip_table = $make_array_len_and_init(256, needle_len);
      const _end4200 = needle_len - 1 | 0;
      let _tmp = 0;
      while (true) {
        const i = _tmp;
        if (i < _end4200) {
          const _tmp$22 = needle.str;
          const _tmp$3 = needle.start + i | 0;
          const _tmp$4 = _tmp$22.charCodeAt(_tmp$3) & 255;
          $bound_check(skip_table, _tmp$4);
          skip_table[_tmp$4] = (needle_len - 1 | 0) - i | 0;
          _tmp = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      let _tmp$2 = 0;
      while (true) {
        const i = _tmp$2;
        if (i <= (haystack_len - needle_len | 0)) {
          const _end4206 = needle_len - 1 | 0;
          let _tmp$3 = 0;
          while (true) {
            const j = _tmp$3;
            if (j <= _end4206) {
              const _p2 = i + j | 0;
              const _tmp$42 = haystack.str;
              const _tmp$52 = haystack.start + _p2 | 0;
              const _p$2 = _tmp$42.charCodeAt(_tmp$52);
              const _tmp$62 = needle.str;
              const _tmp$7 = needle.start + j | 0;
              const _p$3 = _tmp$62.charCodeAt(_tmp$7);
              if (_p$2 !== _p$3) {
                break;
              }
              _tmp$3 = j + 1 | 0;
              continue;
            } else {
              return i;
            }
          }
          const _p = (i + needle_len | 0) - 1 | 0;
          const _tmp$4 = haystack.str;
          const _tmp$5 = haystack.start + _p | 0;
          const _tmp$6 = _tmp$4.charCodeAt(_tmp$5) & 255;
          $bound_check(skip_table, _tmp$6);
          _tmp$2 = i + skip_table[_tmp$6] | 0;
          continue;
        } else {
          break;
        }
      }
      return void 0;
    } else {
      return void 0;
    }
  } else {
    return moonbitlang$core$builtin$$boyer_moore_horspool_find$46$constr$47$189;
  }
}
function moonbitlang$core$builtin$$brute_force_find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const _p = 0;
      const _tmp = needle.str;
      const _tmp$2 = needle.start + _p | 0;
      const needle_first = _tmp.charCodeAt(_tmp$2);
      const forward_len = haystack_len - needle_len | 0;
      let i = 0;
      while (true) {
        if (i <= forward_len) {
          while (true) {
            let _tmp$3;
            if (i <= forward_len) {
              const _p$2 = i;
              const _tmp$4 = haystack.str;
              const _tmp$5 = haystack.start + _p$2 | 0;
              const _p$3 = _tmp$4.charCodeAt(_tmp$5);
              _tmp$3 = _p$3 !== needle_first;
            } else {
              _tmp$3 = false;
            }
            if (_tmp$3) {
              i = i + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          if (i <= forward_len) {
            let _tmp$3 = 1;
            while (true) {
              const j = _tmp$3;
              if (j < needle_len) {
                const _p$2 = i + j | 0;
                const _tmp$4 = haystack.str;
                const _tmp$5 = haystack.start + _p$2 | 0;
                const _p$3 = _tmp$4.charCodeAt(_tmp$5);
                const _tmp$6 = needle.str;
                const _tmp$7 = needle.start + j | 0;
                const _p$4 = _tmp$6.charCodeAt(_tmp$7);
                if (_p$3 !== _p$4) {
                  break;
                }
                _tmp$3 = j + 1 | 0;
                continue;
              } else {
                return i;
              }
            }
            i = i + 1 | 0;
          }
          continue;
        } else {
          break;
        }
      }
      return void 0;
    } else {
      return void 0;
    }
  } else {
    return moonbitlang$core$builtin$$brute_force_find$46$constr$47$203;
  }
}
function moonbitlang$core$string$$StringView$find(self, str) {
  return (str.end - str.start | 0) <= 4 ? moonbitlang$core$builtin$$brute_force_find(self, str) : moonbitlang$core$builtin$$boyer_moore_horspool_find(self, str);
}
function moonbitlang$core$string$$StringView$has_prefix(self, str) {
  const _bind = moonbitlang$core$string$$StringView$find(self, str);
  if (_bind === void 0) {
    return false;
  } else {
    const _Some = _bind;
    const _i = _Some;
    return _i === 0;
  }
}
function moonbitlang$core$string$$String$has_prefix(self, str) {
  return moonbitlang$core$string$$StringView$has_prefix({ str: self, start: 0, end: self.length }, str);
}
function moonbitlang$core$array$$Array$new$46$inner$5$(capacity) {
  return [];
}
function moonbitlang$core$array$$Array$push$8$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$5$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$9$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$10$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$builtin$$Iter$next$5$(self) {
  const _func = self;
  return _func();
}
function moonbitlang$core$string$$String$iter(self) {
  const len = self.length;
  const index = { val: 0 };
  const _p = /* @__PURE__ */ __name(() => {
    if (index.val < len) {
      const _tmp = index.val;
      const c1 = self.charCodeAt(_tmp);
      if (moonbitlang$core$uint16$$UInt16$is_leading_surrogate(c1) && (index.val + 1 | 0) < len) {
        const _tmp$2 = index.val + 1 | 0;
        const c2 = self.charCodeAt(_tmp$2);
        if (moonbitlang$core$uint16$$UInt16$is_trailing_surrogate(c2)) {
          const c = moonbitlang$core$builtin$$code_point_of_surrogate_pair(c1, c2);
          index.val = index.val + 2 | 0;
          return c;
        }
      }
      index.val = index.val + 1 | 0;
      return c1;
    } else {
      return -1;
    }
  }, "_p");
  return _p;
}
function moonbitlang$core$builtin$$ToStringView$to_string_view$10$(self) {
  return { str: self, start: 0, end: self.length };
}
function moonbitlang$core$string$$String$to_array(self) {
  const _p = moonbitlang$core$string$$String$iter(self);
  const _p$2 = moonbitlang$core$array$$Array$new$46$inner$5$(self.length);
  let _p$3 = _p$2;
  while (true) {
    const _p$4 = moonbitlang$core$builtin$$Iter$next$5$(_p);
    if (_p$4 === -1) {
      break;
    } else {
      const _p$5 = _p$4;
      const _p$6 = _p$5;
      const _p$7 = _p$3;
      moonbitlang$core$array$$Array$push$5$(_p$7, _p$6);
      _p$3 = _p$7;
      continue;
    }
  }
  return _p$3;
}
function moonbitlang$core$builtin$$Show$output$11$(self, logger) {
  const pkg = self.pkg;
  const _data = pkg.str;
  const _start = pkg.start;
  const _end = _start + (pkg.end - pkg.start | 0) | 0;
  let _cursor = _start;
  let accept_state = -1;
  let match_end = -1;
  let match_tag_saver_0 = -1;
  let tag_0 = -1;
  let _bind;
  _L: {
    _L$2: {
      _L$3: while (true) {
        if (_cursor < _end) {
          _L$4: {
            _L$5: {
              const _p = _cursor;
              const next_char = _data.charCodeAt(_p);
              _cursor = _cursor + 1 | 0;
              if (next_char < 55296) {
                if (next_char < 47) {
                  break _L$5;
                } else {
                  if (next_char > 47) {
                    break _L$5;
                  } else {
                    _L$6: while (true) {
                      tag_0 = _cursor;
                      if (_cursor < _end) {
                        _L$7: {
                          const _p$2 = _cursor;
                          const next_char$2 = _data.charCodeAt(_p$2);
                          _cursor = _cursor + 1 | 0;
                          if (next_char$2 < 55296) {
                            if (next_char$2 < 47) {
                              break _L$7;
                            } else {
                              if (next_char$2 > 47) {
                                break _L$7;
                              } else {
                                while (true) {
                                  if (_cursor < _end) {
                                    _L$8: {
                                      const _p$3 = _cursor;
                                      const next_char$3 = _data.charCodeAt(_p$3);
                                      _cursor = _cursor + 1 | 0;
                                      if (next_char$3 < 56319) {
                                        if (next_char$3 < 55296) {
                                          break _L$8;
                                        } else {
                                          if (_cursor < _end) {
                                            const _p$4 = _cursor;
                                            const next_char$4 = _data.charCodeAt(_p$4);
                                            _cursor = _cursor + 1 | 0;
                                            if (next_char$4 < 56320) {
                                              break _L$2;
                                            } else {
                                              if (next_char$4 > 65535) {
                                                break _L$2;
                                              } else {
                                                continue;
                                              }
                                            }
                                          } else {
                                            break _L$2;
                                          }
                                        }
                                      } else {
                                        if (next_char$3 > 56319) {
                                          if (next_char$3 < 65536) {
                                            break _L$8;
                                          } else {
                                            break _L$2;
                                          }
                                        } else {
                                          if (_cursor < _end) {
                                            const _p$4 = _cursor;
                                            const next_char$4 = _data.charCodeAt(_p$4);
                                            _cursor = _cursor + 1 | 0;
                                            if (next_char$4 < 56320) {
                                              break _L$2;
                                            } else {
                                              if (next_char$4 > 57343) {
                                                break _L$2;
                                              } else {
                                                continue;
                                              }
                                            }
                                          } else {
                                            break _L$2;
                                          }
                                        }
                                      }
                                    }
                                    continue;
                                  } else {
                                    match_tag_saver_0 = tag_0;
                                    accept_state = 0;
                                    match_end = _cursor;
                                    break _L$2;
                                  }
                                }
                              }
                            }
                          } else {
                            if (next_char$2 > 56318) {
                              if (next_char$2 < 57344) {
                                if (_cursor < _end) {
                                  const _p$3 = _cursor;
                                  const next_char$3 = _data.charCodeAt(_p$3);
                                  _cursor = _cursor + 1 | 0;
                                  if (next_char$3 < 56320) {
                                    break _L$2;
                                  } else {
                                    if (next_char$3 > 57343) {
                                      break _L$2;
                                    } else {
                                      continue;
                                    }
                                  }
                                } else {
                                  break _L$2;
                                }
                              } else {
                                if (next_char$2 > 65535) {
                                  break _L$2;
                                } else {
                                  break _L$7;
                                }
                              }
                            } else {
                              if (_cursor < _end) {
                                const _p$3 = _cursor;
                                const next_char$3 = _data.charCodeAt(_p$3);
                                _cursor = _cursor + 1 | 0;
                                if (next_char$3 < 56320) {
                                  break _L$2;
                                } else {
                                  if (next_char$3 > 65535) {
                                    break _L$2;
                                  } else {
                                    continue;
                                  }
                                }
                              } else {
                                break _L$2;
                              }
                            }
                          }
                        }
                        continue;
                      } else {
                        break _L$2;
                      }
                    }
                  }
                }
              } else {
                if (next_char > 56318) {
                  if (next_char < 57344) {
                    if (_cursor < _end) {
                      const _p$2 = _cursor;
                      const next_char$2 = _data.charCodeAt(_p$2);
                      _cursor = _cursor + 1 | 0;
                      if (next_char$2 < 56320) {
                        break _L$2;
                      } else {
                        if (next_char$2 > 57343) {
                          break _L$2;
                        } else {
                          continue;
                        }
                      }
                    } else {
                      break _L$2;
                    }
                  } else {
                    if (next_char > 65535) {
                      break _L$2;
                    } else {
                      break _L$5;
                    }
                  }
                } else {
                  if (_cursor < _end) {
                    const _p$2 = _cursor;
                    const next_char$2 = _data.charCodeAt(_p$2);
                    _cursor = _cursor + 1 | 0;
                    if (next_char$2 < 56320) {
                      break _L$2;
                    } else {
                      if (next_char$2 > 65535) {
                        break _L$2;
                      } else {
                        continue;
                      }
                    }
                  } else {
                    break _L$2;
                  }
                }
              }
              break _L$4;
            }
            continue;
          }
        } else {
          break _L$2;
        }
      }
      break _L;
    }
    if (accept_state === 0) {
      let package_name;
      let _try_err;
      _L$3: {
        _L$4: {
          const _bind$2 = moonbitlang$core$string$$String$sub(_data, match_tag_saver_0 + 1 | 0, match_end);
          if (_bind$2.$tag === 1) {
            const _ok = _bind$2;
            package_name = _ok._0;
          } else {
            const _err = _bind$2;
            const _tmp = _err._0;
            _try_err = _tmp;
            break _L$4;
          }
          break _L$3;
        }
        package_name = $panic();
      }
      let module_name;
      let _try_err$2;
      _L$4: {
        _L$5: {
          const _bind$2 = moonbitlang$core$string$$String$sub(_data, _start, match_tag_saver_0);
          if (_bind$2.$tag === 1) {
            const _ok = _bind$2;
            module_name = _ok._0;
          } else {
            const _err = _bind$2;
            const _tmp = _err._0;
            _try_err$2 = _tmp;
            break _L$5;
          }
          break _L$4;
        }
        module_name = $panic();
      }
      _bind = { _0: module_name, _1: package_name };
    } else {
      _bind = { _0: pkg, _1: void 0 };
    }
  }
  const _module_name = _bind._0;
  const _package_name = _bind._1;
  if (_package_name === void 0) {
  } else {
    const _Some = _package_name;
    const _pkg_name = _Some;
    logger.method_table.method_2(logger.self, _pkg_name);
    logger.method_table.method_3(logger.self, 47);
  }
  logger.method_table.method_2(logger.self, self.filename);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.start_line);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.start_column);
  logger.method_table.method_3(logger.self, 45);
  logger.method_table.method_2(logger.self, self.end_line);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.end_column);
  logger.method_table.method_3(logger.self, 64);
  logger.method_table.method_2(logger.self, _module_name);
}
function moonbitlang$core$builtin$$Show$output$6$(self, logger) {
  moonbitlang$core$builtin$$Show$output$11$(moonbitlang$core$builtin$$SourceLocRepr$parse(self), logger);
}
function moonbitlang$core$array$$ArrayView$join$10$(self, separator) {
  if ((self.end - self.start | 0) === 0) {
    return "";
  } else {
    const _hd = self.buf[self.start];
    const _bind = self.buf;
    const _bind$2 = 1 + self.start | 0;
    const _bind$3 = self.end;
    const _x = { buf: _bind, start: _bind$2, end: _bind$3 };
    const hd = moonbitlang$core$builtin$$ToStringView$to_string_view$10$(_hd);
    let size_hint = hd.end - hd.start | 0;
    const _len = _x.end - _x.start | 0;
    let _tmp = 0;
    while (true) {
      const _i = _tmp;
      if (_i < _len) {
        const s = _bind[_bind$2 + _i | 0];
        const _tmp$2 = size_hint;
        const _p = moonbitlang$core$builtin$$ToStringView$to_string_view$10$(s);
        size_hint = _tmp$2 + ((_p.end - _p.start | 0) + (separator.end - separator.start | 0) | 0) | 0;
        _tmp = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    size_hint = size_hint << 1;
    const buf = moonbitlang$core$builtin$$StringBuilder$new$46$inner(size_hint);
    moonbitlang$core$builtin$$Logger$write_view$0$(buf, hd);
    if (moonbitlang$core$string$$String$char_length_eq$46$inner(separator.str, 0, separator.start, separator.end)) {
      const _len$2 = _x.end - _x.start | 0;
      let _tmp$2 = 0;
      while (true) {
        const _i = _tmp$2;
        if (_i < _len$2) {
          const s = _bind[_bind$2 + _i | 0];
          const s$2 = moonbitlang$core$builtin$$ToStringView$to_string_view$10$(s);
          moonbitlang$core$builtin$$Logger$write_view$0$(buf, s$2);
          _tmp$2 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    } else {
      const _len$2 = _x.end - _x.start | 0;
      let _tmp$2 = 0;
      while (true) {
        const _i = _tmp$2;
        if (_i < _len$2) {
          const s = _bind[_bind$2 + _i | 0];
          const s$2 = moonbitlang$core$builtin$$ToStringView$to_string_view$10$(s);
          moonbitlang$core$builtin$$Logger$write_view$0$(buf, separator);
          moonbitlang$core$builtin$$Logger$write_view$0$(buf, s$2);
          _tmp$2 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    }
    return buf.val;
  }
}
function moonbitlang$core$array$$Array$join$10$(self, separator) {
  return moonbitlang$core$array$$ArrayView$join$10$({ buf: self, start: 0, end: self.length }, separator);
}
function f4ah6o$blog$46$mbt$models$$BlogPost$new(id, title, slug, excerpt, content, published_at, updated_at) {
  return { id, title, slug, excerpt, content, published_at, updated_at };
}
function f4ah6o$tmpx$tmpx$$Tag$is_void(self) {
  switch (self.$tag) {
    case 69: {
      return true;
    }
    case 4: {
      return true;
    }
    case 117: {
      return true;
    }
    case 118: {
      return true;
    }
    case 45: {
      return true;
    }
    case 89: {
      return true;
    }
    case 78: {
      return true;
    }
    case 124: {
      return true;
    }
    case 33: {
      return true;
    }
    case 71: {
      return true;
    }
    case 100: {
      return true;
    }
    case 126: {
      return true;
    }
    case 127: {
      return true;
    }
    case 5: {
      return true;
    }
    case 130: {
      return true;
    }
    case 6: {
      return true;
    }
    case 132: {
      return true;
    }
    case 81: {
      return true;
    }
    case 74: {
      return true;
    }
    case 137: {
      return true;
    }
    case 75: {
      return true;
    }
    case 68: {
      return true;
    }
    default: {
      return false;
    }
  }
}
function f4ah6o$tmpx$tmpx$$Tag$element(self, attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$is_void(self) ? new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$VoidElement(self, attrs) : new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Element(self, attrs, children);
}
function f4ah6o$tmpx$tmpx$$html_(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Html, attrs, children);
}
function f4ah6o$tmpx$tmpx$$head(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Head, attrs, children);
}
function f4ah6o$tmpx$tmpx$$body(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Body, attrs, children);
}
function f4ah6o$tmpx$tmpx$$title(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Title, attrs, children);
}
function f4ah6o$tmpx$tmpx$$link(attrs) {
  const _p = $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Link;
  return new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$VoidElement(_p, attrs);
}
function f4ah6o$tmpx$tmpx$$meta(attrs) {
  const _p = $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Meta;
  return new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$VoidElement(_p, attrs);
}
function f4ah6o$tmpx$tmpx$$script(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Script, attrs, children);
}
function f4ah6o$tmpx$tmpx$$article(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Article, attrs, children);
}
function f4ah6o$tmpx$tmpx$$footer(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Footer, attrs, children);
}
function f4ah6o$tmpx$tmpx$$header_(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Header, attrs, children);
}
function f4ah6o$tmpx$tmpx$$h1(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$H1, attrs, children);
}
function f4ah6o$tmpx$tmpx$$h2(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$H2, attrs, children);
}
function f4ah6o$tmpx$tmpx$$main_(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Main, attrs, children);
}
function f4ah6o$tmpx$tmpx$$nav(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Nav, attrs, children);
}
function f4ah6o$tmpx$tmpx$$div(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Div, attrs, children);
}
function f4ah6o$tmpx$tmpx$$li(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Li, attrs, children);
}
function f4ah6o$tmpx$tmpx$$p(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$P, attrs, children);
}
function f4ah6o$tmpx$tmpx$$ul(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Ul, attrs, children);
}
function f4ah6o$tmpx$tmpx$$a(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$A, attrs, children);
}
function f4ah6o$tmpx$tmpx$$span(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Span, attrs, children);
}
function f4ah6o$tmpx$tmpx$$time(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Time, attrs, children);
}
function f4ah6o$tmpx$tmpx$$button(attrs, children) {
  return f4ah6o$tmpx$tmpx$$Tag$element($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Button, attrs, children);
}
function f4ah6o$tmpx$tmpx$$Tag$to_string(self) {
  switch (self.$tag) {
    case 0: {
      return "html";
    }
    case 1: {
      return "head";
    }
    case 2: {
      return "body";
    }
    case 3: {
      return "title";
    }
    case 4: {
      return "base";
    }
    case 5: {
      return "link";
    }
    case 6: {
      return "meta";
    }
    case 7: {
      return "style";
    }
    case 8: {
      return "script";
    }
    case 9: {
      return "noscript";
    }
    case 10: {
      return "address";
    }
    case 11: {
      return "article";
    }
    case 12: {
      return "aside";
    }
    case 13: {
      return "footer";
    }
    case 14: {
      return "header";
    }
    case 15: {
      return "h1";
    }
    case 16: {
      return "h2";
    }
    case 17: {
      return "h3";
    }
    case 18: {
      return "h4";
    }
    case 19: {
      return "h5";
    }
    case 20: {
      return "h6";
    }
    case 21: {
      return "hgroup";
    }
    case 22: {
      return "main";
    }
    case 23: {
      return "nav";
    }
    case 24: {
      return "section";
    }
    case 25: {
      return "search";
    }
    case 26: {
      return "blockquote";
    }
    case 27: {
      return "div";
    }
    case 28: {
      return "dl";
    }
    case 29: {
      return "dt";
    }
    case 30: {
      return "dd";
    }
    case 31: {
      return "figure";
    }
    case 32: {
      return "figcaption";
    }
    case 33: {
      return "hr";
    }
    case 34: {
      return "li";
    }
    case 35: {
      return "menu";
    }
    case 36: {
      return "ol";
    }
    case 37: {
      return "p";
    }
    case 38: {
      return "pre";
    }
    case 39: {
      return "ul";
    }
    case 40: {
      return "a";
    }
    case 41: {
      return "abbr";
    }
    case 42: {
      return "b";
    }
    case 43: {
      return "bdi";
    }
    case 44: {
      return "bdo";
    }
    case 45: {
      return "br";
    }
    case 46: {
      return "cite";
    }
    case 47: {
      return "code";
    }
    case 48: {
      return "data";
    }
    case 49: {
      return "dfn";
    }
    case 50: {
      return "em";
    }
    case 51: {
      return "i";
    }
    case 52: {
      return "kbd";
    }
    case 53: {
      return "mark";
    }
    case 54: {
      return "q";
    }
    case 55: {
      return "ruby";
    }
    case 56: {
      return "rp";
    }
    case 57: {
      return "rt";
    }
    case 58: {
      return "s";
    }
    case 59: {
      return "samp";
    }
    case 60: {
      return "small";
    }
    case 61: {
      return "span";
    }
    case 62: {
      return "strong";
    }
    case 63: {
      return "sub";
    }
    case 64: {
      return "sup";
    }
    case 65: {
      return "time";
    }
    case 66: {
      return "u";
    }
    case 67: {
      return "var";
    }
    case 68: {
      return "wbr";
    }
    case 69: {
      return "area";
    }
    case 70: {
      return "audio";
    }
    case 71: {
      return "img";
    }
    case 72: {
      return "map";
    }
    case 73: {
      return "picture";
    }
    case 74: {
      return "source";
    }
    case 75: {
      return "track";
    }
    case 76: {
      return "video";
    }
    case 77: {
      return "canvas";
    }
    case 78: {
      return "embed";
    }
    case 79: {
      return "iframe";
    }
    case 80: {
      return "object";
    }
    case 81: {
      return "param";
    }
    case 82: {
      return "svg";
    }
    case 83: {
      return "math";
    }
    case 84: {
      return "del";
    }
    case 85: {
      return "ins";
    }
    case 86: {
      return "table";
    }
    case 87: {
      return "caption";
    }
    case 88: {
      return "colgroup";
    }
    case 89: {
      return "col";
    }
    case 90: {
      return "tbody";
    }
    case 91: {
      return "thead";
    }
    case 92: {
      return "tfoot";
    }
    case 93: {
      return "tr";
    }
    case 94: {
      return "th";
    }
    case 95: {
      return "td";
    }
    case 96: {
      return "button";
    }
    case 97: {
      return "datalist";
    }
    case 98: {
      return "fieldset";
    }
    case 99: {
      return "form";
    }
    case 100: {
      return "input";
    }
    case 101: {
      return "label";
    }
    case 102: {
      return "legend";
    }
    case 103: {
      return "meter";
    }
    case 104: {
      return "optgroup";
    }
    case 105: {
      return "option";
    }
    case 106: {
      return "output";
    }
    case 107: {
      return "progress";
    }
    case 108: {
      return "select";
    }
    case 109: {
      return "textarea";
    }
    case 110: {
      return "details";
    }
    case 111: {
      return "dialog";
    }
    case 112: {
      return "summary";
    }
    case 113: {
      return "slot";
    }
    case 114: {
      return "template";
    }
    case 115: {
      return "acronym";
    }
    case 116: {
      return "applet";
    }
    case 117: {
      return "basefont";
    }
    case 118: {
      return "bgsound";
    }
    case 119: {
      return "big";
    }
    case 120: {
      return "blink";
    }
    case 121: {
      return "center";
    }
    case 122: {
      return "dir";
    }
    case 123: {
      return "font";
    }
    case 124: {
      return "frame";
    }
    case 125: {
      return "frameset";
    }
    case 126: {
      return "isindex";
    }
    case 127: {
      return "keygen";
    }
    case 128: {
      return "listing";
    }
    case 129: {
      return "marquee";
    }
    case 130: {
      return "menuitem";
    }
    case 131: {
      return "multicol";
    }
    case 132: {
      return "nextid";
    }
    case 133: {
      return "nobr";
    }
    case 134: {
      return "noembed";
    }
    case 135: {
      return "noframes";
    }
    case 136: {
      return "plaintext";
    }
    case 137: {
      return "spacer";
    }
    case 138: {
      return "strike";
    }
    case 139: {
      return "tt";
    }
    case 140: {
      return "xmp";
    }
    default: {
      const _Custom = self;
      return _Custom._0;
    }
  }
}
function f4ah6o$tmpx$tmpx$$escape_html(text) {
  const sb = moonbitlang$core$builtin$$StringBuilder$new$46$inner(text.length);
  const _it = moonbitlang$core$string$$String$iter(text);
  while (true) {
    const _bind = moonbitlang$core$builtin$$Iter$next$5$(_it);
    if (_bind === -1) {
      break;
    } else {
      const _Some = _bind;
      const _c = _Some;
      switch (_c) {
        case 38: {
          moonbitlang$core$builtin$$Logger$write_string$0$(sb, "&amp;");
          break;
        }
        case 60: {
          moonbitlang$core$builtin$$Logger$write_string$0$(sb, "&lt;");
          break;
        }
        case 62: {
          moonbitlang$core$builtin$$Logger$write_string$0$(sb, "&gt;");
          break;
        }
        case 34: {
          moonbitlang$core$builtin$$Logger$write_string$0$(sb, "&quot;");
          break;
        }
        case 39: {
          moonbitlang$core$builtin$$Logger$write_string$0$(sb, "&#39;");
          break;
        }
        default: {
          moonbitlang$core$builtin$$Logger$write_char$0$(sb, _c);
        }
      }
      continue;
    }
  }
  return sb.val;
}
function f4ah6o$tmpx$tmpx$$render_kv_attr(sb, name, value) {
  moonbitlang$core$builtin$$Logger$write_char$0$(sb, 32);
  moonbitlang$core$builtin$$Logger$write_string$0$(sb, name);
  moonbitlang$core$builtin$$Logger$write_string$0$(sb, '="');
  moonbitlang$core$builtin$$Logger$write_string$0$(sb, f4ah6o$tmpx$tmpx$$escape_html(value));
  moonbitlang$core$builtin$$Logger$write_char$0$(sb, 34);
}
function f4ah6o$tmpx$tmpx$$Attr$render_into(self, sb) {
  switch (self.$tag) {
    case 0: {
      const _KeyVal = self;
      const _name = _KeyVal._0;
      const _value = _KeyVal._1;
      f4ah6o$tmpx$tmpx$$render_kv_attr(sb, _name, _value);
      return;
    }
    case 1: {
      const _Bool = self;
      const _name$2 = _Bool._0;
      moonbitlang$core$builtin$$Logger$write_char$0$(sb, 32);
      moonbitlang$core$builtin$$Logger$write_string$0$(sb, _name$2);
      return;
    }
    default: {
      const _ClassList = self;
      const _values = _ClassList._0;
      const _p = [];
      const _p$2 = _values.length;
      let _tmp = 0;
      while (true) {
        const _p$32 = _tmp;
        if (_p$32 < _p$2) {
          const _p$4 = _values[_p$32];
          const _p$5 = "";
          if (!(_p$4 === _p$5)) {
            moonbitlang$core$array$$Array$push$10$(_p, _p$4);
          }
          _tmp = _p$32 + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const class_value = moonbitlang$core$array$$Array$join$10$(_p, { str: f4ah6o$tmpx$tmpx$$render_into$46$42$bind$124$1231, start: 0, end: f4ah6o$tmpx$tmpx$$render_into$46$42$bind$124$1231.length });
      const _p$3 = "";
      if (!(class_value === _p$3)) {
        f4ah6o$tmpx$tmpx$$render_kv_attr(sb, "class", class_value);
        return;
      } else {
        return;
      }
    }
  }
}
function f4ah6o$tmpx$tmpx$$render_attrs(sb, attrs) {
  const _len = attrs.end - attrs.start | 0;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const attr = attrs.buf[attrs.start + _i | 0];
      f4ah6o$tmpx$tmpx$$Attr$render_into(attr, sb);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function f4ah6o$tmpx$tmpx$$Node$render_into(self, sb) {
  switch (self.$tag) {
    case 2: {
      const _Text = self;
      const _content = _Text._0;
      moonbitlang$core$builtin$$Logger$write_string$0$(sb, f4ah6o$tmpx$tmpx$$escape_html(_content));
      return;
    }
    case 3: {
      const _Raw = self;
      const _content$2 = _Raw._0;
      moonbitlang$core$builtin$$Logger$write_string$0$(sb, _content$2);
      return;
    }
    case 4: {
      const _Fragment = self;
      const _children = _Fragment._0;
      const _len = _children.length;
      let _tmp = 0;
      while (true) {
        const _i = _tmp;
        if (_i < _len) {
          const child = _children[_i];
          f4ah6o$tmpx$tmpx$$Node$render_into(child, sb);
          _tmp = _i + 1 | 0;
          continue;
        } else {
          return;
        }
      }
    }
    case 0: {
      const _Element = self;
      const _tag = _Element._0;
      const _attrs = _Element._1;
      const _children$2 = _Element._2;
      moonbitlang$core$builtin$$Logger$write_char$0$(sb, 60);
      moonbitlang$core$builtin$$Logger$write_string$0$(sb, f4ah6o$tmpx$tmpx$$Tag$to_string(_tag));
      f4ah6o$tmpx$tmpx$$render_attrs(sb, { buf: _attrs, start: 0, end: _attrs.length });
      moonbitlang$core$builtin$$Logger$write_char$0$(sb, 62);
      const _len$2 = _children$2.length;
      let _tmp$2 = 0;
      while (true) {
        const _i = _tmp$2;
        if (_i < _len$2) {
          const child = _children$2[_i];
          f4ah6o$tmpx$tmpx$$Node$render_into(child, sb);
          _tmp$2 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      moonbitlang$core$builtin$$Logger$write_string$0$(sb, "</");
      moonbitlang$core$builtin$$Logger$write_string$0$(sb, f4ah6o$tmpx$tmpx$$Tag$to_string(_tag));
      moonbitlang$core$builtin$$Logger$write_char$0$(sb, 62);
      return;
    }
    default: {
      const _VoidElement = self;
      const _tag$2 = _VoidElement._0;
      const _attrs$2 = _VoidElement._1;
      moonbitlang$core$builtin$$Logger$write_char$0$(sb, 60);
      moonbitlang$core$builtin$$Logger$write_string$0$(sb, f4ah6o$tmpx$tmpx$$Tag$to_string(_tag$2));
      f4ah6o$tmpx$tmpx$$render_attrs(sb, { buf: _attrs$2, start: 0, end: _attrs$2.length });
      moonbitlang$core$builtin$$Logger$write_char$0$(sb, 62);
      return;
    }
  }
}
function f4ah6o$tmpx$tmpx$$render(node) {
  const sb = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  f4ah6o$tmpx$tmpx$$Node$render_into(node, sb);
  return sb.val;
}
function f4ah6o$tmpx$tmpx$$MxSwap$to_string(self) {
  switch (self) {
    case 0: {
      return "innerHTML";
    }
    case 1: {
      return "outerHTML";
    }
    case 2: {
      return "beforebegin";
    }
    case 3: {
      return "afterbegin";
    }
    case 4: {
      return "beforeend";
    }
    case 5: {
      return "afterend";
    }
    case 6: {
      return "delete";
    }
    default: {
      return "none";
    }
  }
}
function f4ah6o$tmpx$tmpx$$mx_get(url) {
  const _p = "mx-get";
  return new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal(_p, url);
}
function f4ah6o$tmpx$tmpx$$mx_target(selector) {
  const _p = "mx-target";
  return new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal(_p, selector);
}
function f4ah6o$tmpx$tmpx$$mx_swap(style) {
  const _p = "mx-swap";
  const _p$2 = f4ah6o$tmpx$tmpx$$MxSwap$to_string(style);
  return new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal(_p, _p$2);
}
function f4ah6o$tmpx$tmpx$$mx_push_url_custom(url) {
  const _p = "mx-push-url";
  return new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal(_p, url);
}
function f4ah6o$blog$46$mbt$templates$$format_date(iso_date) {
  if (iso_date.length >= 10) {
    const chars = moonbitlang$core$string$$String$to_array(iso_date);
    const date_chars = [];
    let _tmp = 0;
    while (true) {
      const i = _tmp;
      if (i < 10) {
        moonbitlang$core$array$$Array$push$5$(date_chars, moonbitlang$core$array$$Array$at$5$(chars, i));
        _tmp = i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    return moonbitlang$core$string$$String$from_array({ buf: date_chars, start: 0, end: date_chars.length });
  } else {
    return iso_date;
  }
}
function f4ah6o$blog$46$mbt$templates$$post_card(post) {
  const _p = "post-card";
  const _tmp = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p)];
  const _p$2 = "post-title";
  const _tmp$2 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$2)];
  const _p$3 = `/posts/${post.slug}`;
  const _tmp$3 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("href", _p$3)];
  const _p$4 = post.title;
  const _tmp$4 = f4ah6o$tmpx$tmpx$$h2(_tmp$2, [f4ah6o$tmpx$tmpx$$a(_tmp$3, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$4)])]);
  const _p$5 = "post-excerpt";
  const _tmp$5 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$5)];
  const _p$6 = post.excerpt;
  const _tmp$6 = f4ah6o$tmpx$tmpx$$p(_tmp$5, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$6)]);
  const _p$7 = "post-meta";
  const _tmp$7 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$7)];
  const _p$8 = "datetime";
  const _p$9 = post.published_at;
  const _tmp$8 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal(_p$8, _p$9)];
  const _p$10 = f4ah6o$blog$46$mbt$templates$$format_date(post.published_at);
  return f4ah6o$tmpx$tmpx$$article(_tmp, [_tmp$4, _tmp$6, f4ah6o$tmpx$tmpx$$div(_tmp$7, [f4ah6o$tmpx$tmpx$$time(_tmp$8, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$10)])])]);
}
function f4ah6o$blog$46$mbt$templates$$pagination_buttons(page, total_pages, limit) {
  const prev_disabled = page <= 1;
  const next_disabled = page >= total_pages;
  let prev_attrs;
  if (prev_disabled) {
    const _p2 = "btn btn-prev";
    prev_attrs = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p2), f4ah6o$tmpx$tmpx$$disabled$46$constr$47$465];
  } else {
    const prev_url = `/api/posts?page=${moonbitlang$core$int$$Int$to_string$46$inner(page - 1 | 0, 10)}&limit=${moonbitlang$core$int$$Int$to_string$46$inner(limit, 10)}`;
    const _p2 = "btn btn-prev";
    prev_attrs = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p2), f4ah6o$tmpx$tmpx$$mx_get(prev_url), f4ah6o$tmpx$tmpx$$mx_target("#posts-container"), f4ah6o$tmpx$tmpx$$mx_swap(0), f4ah6o$tmpx$tmpx$$mx_push_url_custom(`/posts?page=${moonbitlang$core$int$$Int$to_string$46$inner(page - 1 | 0, 10)}&limit=${moonbitlang$core$int$$Int$to_string$46$inner(limit, 10)}`)];
  }
  let next_attrs;
  if (next_disabled) {
    const _p2 = "btn btn-next";
    next_attrs = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p2), f4ah6o$tmpx$tmpx$$disabled$46$constr$47$465];
  } else {
    const next_url = `/api/posts?page=${moonbitlang$core$int$$Int$to_string$46$inner(page + 1 | 0, 10)}&limit=${moonbitlang$core$int$$Int$to_string$46$inner(limit, 10)}`;
    const _p2 = "btn btn-next";
    next_attrs = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p2), f4ah6o$tmpx$tmpx$$mx_get(next_url), f4ah6o$tmpx$tmpx$$mx_target("#posts-container"), f4ah6o$tmpx$tmpx$$mx_swap(0), f4ah6o$tmpx$tmpx$$mx_push_url_custom(`/posts?page=${moonbitlang$core$int$$Int$to_string$46$inner(page + 1 | 0, 10)}&limit=${moonbitlang$core$int$$Int$to_string$46$inner(limit, 10)}`)];
  }
  const _p = "pagination";
  const _tmp = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p)];
  const _p$2 = "Prev";
  const _tmp$2 = f4ah6o$tmpx$tmpx$$button(prev_attrs, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$2)]);
  const _p$3 = "page-info";
  const _tmp$3 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$3)];
  const _p$4 = `Page ${moonbitlang$core$int$$Int$to_string$46$inner(page, 10)} of ${moonbitlang$core$int$$Int$to_string$46$inner(total_pages, 10)}`;
  const _tmp$4 = f4ah6o$tmpx$tmpx$$span(_tmp$3, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$4)]);
  const _p$5 = "Next";
  return f4ah6o$tmpx$tmpx$$div(_tmp, [_tmp$2, _tmp$4, f4ah6o$tmpx$tmpx$$button(next_attrs, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$5)])]);
}
function f4ah6o$blog$46$mbt$templates$$post_list_content(posts, page, total_pages, limit) {
  if (posts.length === 0) {
    const _p = "empty-list";
    const _tmp2 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p)];
    const _tmp$2 = [];
    const _p$2 = "No posts found.";
    return f4ah6o$tmpx$tmpx$$div(_tmp2, [f4ah6o$tmpx$tmpx$$p(_tmp$2, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$2)])]);
  }
  const cards = [];
  const _len = posts.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const post = posts[_i];
      moonbitlang$core$array$$Array$push$9$(cards, f4ah6o$blog$46$mbt$templates$$post_card(post));
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  moonbitlang$core$array$$Array$push$9$(cards, f4ah6o$blog$46$mbt$templates$$pagination_buttons(page, total_pages, limit));
  return new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Fragment(cards);
}
function f4ah6o$blog$46$mbt$templates$$render_post_list(posts, page, total_pages, limit) {
  return f4ah6o$tmpx$tmpx$$render(f4ah6o$blog$46$mbt$templates$$post_list_content(posts, page, total_pages, limit));
}
function f4ah6o$blog$46$mbt$templates$$post_detail_content(post) {
  const _p = "post-detail";
  const _tmp = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p)];
  const _p$2 = "post-header";
  const _tmp$2 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$2)];
  const _tmp$3 = [];
  const _p$3 = post.title;
  const _tmp$4 = f4ah6o$tmpx$tmpx$$h1(_tmp$3, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$3)]);
  const _p$4 = "post-meta";
  const _tmp$5 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$4)];
  const _p$5 = "datetime";
  const _p$6 = post.published_at;
  const _tmp$6 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal(_p$5, _p$6)];
  const _p$7 = f4ah6o$blog$46$mbt$templates$$format_date(post.published_at);
  const _tmp$7 = f4ah6o$tmpx$tmpx$$header_(_tmp$2, [_tmp$4, f4ah6o$tmpx$tmpx$$div(_tmp$5, [f4ah6o$tmpx$tmpx$$time(_tmp$6, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$7)])])]);
  const _p$8 = "post-content";
  const _tmp$8 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$8)];
  const _tmp$9 = [];
  const _p$9 = post.content;
  const _tmp$10 = f4ah6o$tmpx$tmpx$$div(_tmp$8, [f4ah6o$tmpx$tmpx$$p(_tmp$9, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$9)])]);
  const _p$10 = "post-footer";
  const _tmp$11 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$10)];
  const _p$11 = "/posts";
  const _tmp$12 = new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("href", _p$11);
  const _p$12 = "btn";
  const _tmp$13 = [_tmp$12, new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$12)];
  const _p$13 = "Back to Posts";
  return f4ah6o$tmpx$tmpx$$article(_tmp, [_tmp$7, _tmp$10, f4ah6o$tmpx$tmpx$$footer(_tmp$11, [f4ah6o$tmpx$tmpx$$a(_tmp$13, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$13)])])]);
}
function f4ah6o$blog$46$mbt$templates$$layout(title, content) {
  const _p = "<!DOCTYPE html>";
  const page = new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Raw(_p);
  const _p$2 = "en";
  const _tmp = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("lang", _p$2)];
  const _tmp$2 = [];
  const _p$3 = "UTF-8";
  const _tmp$3 = f4ah6o$tmpx$tmpx$$meta([new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("charset", _p$3)]);
  const _p$4 = "name";
  const _p$5 = "viewport";
  const _tmp$4 = new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal(_p$4, _p$5);
  const _p$6 = "width=device-width, initial-scale=1.0";
  const _tmp$5 = f4ah6o$tmpx$tmpx$$meta([_tmp$4, new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("content", _p$6)]);
  const _tmp$6 = f4ah6o$tmpx$tmpx$$title([], [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(title)]);
  const _p$7 = "stylesheet";
  const _tmp$7 = new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("rel", _p$7);
  const _p$8 = "/static/styles.css";
  const _tmp$8 = f4ah6o$tmpx$tmpx$$head(_tmp$2, [_tmp$3, _tmp$5, _tmp$6, f4ah6o$tmpx$tmpx$$link([_tmp$7, new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("href", _p$8)])]);
  const _tmp$9 = [];
  const _p$9 = "navbar";
  const _tmp$10 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$9)];
  const _p$10 = "container";
  const _tmp$11 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$10)];
  const _p$11 = "/";
  const _tmp$12 = new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("href", _p$11);
  const _p$12 = "logo";
  const _tmp$13 = [_tmp$12, new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$12)];
  const _p$13 = "MoonBit Blog";
  const _tmp$14 = f4ah6o$tmpx$tmpx$$a(_tmp$13, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$13)]);
  const _p$14 = "nav-links";
  const _tmp$15 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$14)];
  const _tmp$16 = [];
  const _p$15 = "/posts";
  const _tmp$17 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("href", _p$15)];
  const _p$16 = "Posts";
  const _tmp$18 = f4ah6o$tmpx$tmpx$$nav(_tmp$10, [f4ah6o$tmpx$tmpx$$div(_tmp$11, [_tmp$14, f4ah6o$tmpx$tmpx$$ul(_tmp$15, [f4ah6o$tmpx$tmpx$$li(_tmp$16, [f4ah6o$tmpx$tmpx$$a(_tmp$17, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$16)])])])])]);
  const _p$17 = "content";
  const _tmp$19 = new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("id", _p$17);
  const _p$18 = "container";
  const _tmp$20 = [_tmp$19, new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$18)];
  const _p$19 = "posts-container";
  const _tmp$21 = f4ah6o$tmpx$tmpx$$main_(_tmp$20, [f4ah6o$tmpx$tmpx$$div([new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("id", _p$19)], [content])]);
  const _p$20 = "footer";
  const _tmp$22 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$20)];
  const _p$21 = "container";
  const _tmp$23 = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$21)];
  const _tmp$24 = [];
  const _p$22 = "Built with MoonBit, TMPX, MHX, and Cloudflare Workers";
  const _tmp$25 = f4ah6o$tmpx$tmpx$$footer(_tmp$22, [f4ah6o$tmpx$tmpx$$div(_tmp$23, [f4ah6o$tmpx$tmpx$$p(_tmp$24, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$22)])])]);
  const _p$23 = "/mhx.js";
  const _tmp$26 = new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("src", _p$23);
  const _p$24 = "defer";
  const html = f4ah6o$tmpx$tmpx$$html_(_tmp, [_tmp$8, f4ah6o$tmpx$tmpx$$body(_tmp$9, [_tmp$18, _tmp$21, _tmp$25, f4ah6o$tmpx$tmpx$$script([_tmp$26, new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$Bool(_p$24)], [])])]);
  const _p$25 = [page, html];
  return f4ah6o$tmpx$tmpx$$render(new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Fragment(_p$25));
}
function f4ah6o$blog$46$mbt$templates$$error_layout(title, message) {
  const _p = "error-page";
  const _tmp = [new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p)];
  const _tmp$2 = f4ah6o$tmpx$tmpx$$h1([], [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(title)]);
  const _tmp$3 = f4ah6o$tmpx$tmpx$$p([], [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(message)]);
  const _p$2 = "/posts";
  const _tmp$4 = new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("href", _p$2);
  const _p$3 = "btn";
  const _tmp$5 = [_tmp$4, new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal("class", _p$3)];
  const _p$4 = "Back to Posts";
  return f4ah6o$blog$46$mbt$templates$$layout(title, f4ah6o$tmpx$tmpx$$div(_tmp, [_tmp$2, _tmp$3, f4ah6o$tmpx$tmpx$$a(_tmp$5, [new $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text(_p$4)])]));
}
function mizchi$js$core$$Promise$then$12$(self, resolve) {
  return mizchi$js$core$$ffi_promise_then(self, (a) => {
    let _try_err;
    _L: {
      const _bind = resolve(a);
      if (_bind.$tag === 1) {
        const _ok = _bind;
        return _ok._0;
      } else {
        const _err = _bind;
        const _tmp = _err._0;
        _try_err = _tmp;
        break _L;
      }
    }
    return mizchi$js$core$$ffi_promise_reject(_try_err);
  });
}
function mizchi$js$core$$Promise$then$13$(self, resolve) {
  return mizchi$js$core$$ffi_promise_then(self, (a) => {
    let _try_err;
    _L: {
      const _bind = resolve(a);
      if (_bind.$tag === 1) {
        const _ok = _bind;
        return _ok._0;
      } else {
        const _err = _bind;
        const _tmp = _err._0;
        _try_err = _tmp;
        break _L;
      }
    }
    return mizchi$js$core$$ffi_promise_reject(_try_err);
  });
}
function mizchi$js$builtins$global$$parseInt$46$inner(string, radix) {
  const result = mizchi$js$builtins$global$$ffi_parse_int(string, radix);
  return mizchi$js$builtins$global$$isNaN(result) ? void 0 : result;
}
function mizchi$cloudflare$$js_number_to_int(value) {
  return mizchi$cloudflare$$js_number_to_int_ffi(value);
}
function f4ah6o$blog$46$mbt$worker$$extract_slug(pathname) {
  if (moonbitlang$core$string$$String$has_prefix(pathname, { str: f4ah6o$blog$46$mbt$worker$$extract_slug$46$prefix$124$71, start: 0, end: f4ah6o$blog$46$mbt$worker$$extract_slug$46$prefix$124$71.length }) && pathname.length > f4ah6o$blog$46$mbt$worker$$extract_slug$46$prefix$124$71.length) {
    const chars = moonbitlang$core$string$$String$to_array(pathname);
    const slug_chars = [];
    let _tmp = f4ah6o$blog$46$mbt$worker$$extract_slug$46$prefix$124$71.length;
    while (true) {
      const i = _tmp;
      if (i < chars.length) {
        moonbitlang$core$array$$Array$push$5$(slug_chars, moonbitlang$core$array$$Array$at$5$(chars, i));
        _tmp = i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    const slug = moonbitlang$core$string$$String$from_array({ buf: slug_chars, start: 0, end: slug_chars.length });
    return slug.length > 0 ? slug : void 0;
  } else {
    return void 0;
  }
}
function f4ah6o$blog$46$mbt$worker$$parse_page(value) {
  if (value === void 0) {
    return 1;
  } else {
    const _Some = value;
    const _v = _Some;
    const _bind = mizchi$js$builtins$global$$parseInt$46$inner(_v, 10);
    if (_bind === void 0) {
      return 1;
    } else {
      const _Some$2 = _bind;
      const _n = _Some$2;
      return _n >= 1 ? _n : 1;
    }
  }
}
function f4ah6o$blog$46$mbt$worker$$parse_limit(value) {
  if (value === void 0) {
    return 10;
  } else {
    const _Some = value;
    const _v = _Some;
    const _bind = mizchi$js$builtins$global$$parseInt$46$inner(_v, 10);
    if (_bind === void 0) {
      return 10;
    } else {
      const _Some$2 = _bind;
      const _n = _Some$2;
      return _n < 1 ? 10 : _n > 50 ? 50 : _n;
    }
  }
}
function f4ah6o$blog$46$mbt$worker$$row_to_post(row) {
  const id = mizchi$cloudflare$$js_number_to_int(mizchi$js$core$$Any$_get(row, "id"));
  const title = mizchi$js$core$$Any$_get(row, "title");
  const slug = mizchi$js$core$$Any$_get(row, "slug");
  const excerpt_raw = mizchi$js$core$$Any$_get(row, "excerpt");
  const excerpt = mizchi$js$core$$is_null(excerpt_raw) ? "" : excerpt_raw;
  const content = mizchi$js$core$$Any$_get(row, "content");
  const published_at = mizchi$js$core$$Any$_get(row, "published_at");
  const updated_at = mizchi$js$core$$Any$_get(row, "updated_at");
  return f4ah6o$blog$46$mbt$models$$BlogPost$new(id, title, slug, excerpt, content, published_at, updated_at);
}
function f4ah6o$blog$46$mbt$worker$$get_fetch_handler() {
  return (req, env, _ctx) => {
    const url = f4ah6o$blog$46$mbt$worker$$parse_url(req.url);
    const pathname = f4ah6o$blog$46$mbt$worker$$get_pathname(url);
    const db = f4ah6o$blog$46$mbt$worker$$get_db_from_env(env);
    if (mizchi$js$core$$typeof_(db) === "undefined") {
      return f4ah6o$blog$46$mbt$worker$$promise_resolve(f4ah6o$blog$46$mbt$worker$$html_response_js("<!DOCTYPE html><html><body><h1>500 Error</h1><p>Database not configured</p></body></html>", 500));
    }
    if (pathname === "/api/posts") {
      const page = f4ah6o$blog$46$mbt$worker$$parse_page(f4ah6o$blog$46$mbt$worker$$get_search_param(url, "page"));
      const limit = f4ah6o$blog$46$mbt$worker$$parse_limit(f4ah6o$blog$46$mbt$worker$$get_search_param(url, "limit"));
      const offset = Math.imul(page - 1 | 0, limit) | 0;
      return mizchi$js$core$$Promise$then$12$(f4ah6o$blog$46$mbt$worker$$db_count_posts(db), (total) => {
        const total_pages = total === 0 ? 1 : ((total + limit | 0) - 1 | 0) / limit | 0;
        return new Result$Ok$1$(mizchi$js$core$$Promise$then$13$(f4ah6o$blog$46$mbt$worker$$db_list_posts(db, limit, offset), (rows) => {
          const posts = [];
          const rows_arr = rows;
          const _len = rows_arr.length;
          let _tmp = 0;
          while (true) {
            const _i = _tmp;
            if (_i < _len) {
              const row = rows_arr[_i];
              moonbitlang$core$array$$Array$push$8$(posts, f4ah6o$blog$46$mbt$worker$$row_to_post(row));
              _tmp = _i + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          const html = f4ah6o$blog$46$mbt$templates$$render_post_list(posts, page, total_pages, limit);
          return new Result$Ok$1$(f4ah6o$blog$46$mbt$worker$$promise_resolve(f4ah6o$blog$46$mbt$worker$$html_response_js(html, 200)));
        }));
      });
    }
    const _bind = f4ah6o$blog$46$mbt$worker$$extract_slug(pathname);
    if (_bind === void 0) {
    } else {
      const _Some = _bind;
      const _slug = _Some;
      return mizchi$js$core$$Promise$then$13$(f4ah6o$blog$46$mbt$worker$$db_get_post_by_slug(db, _slug), (row) => {
        let _tmp;
        if (mizchi$js$core$$is_null(row)) {
          _tmp = f4ah6o$blog$46$mbt$worker$$promise_resolve(f4ah6o$blog$46$mbt$worker$$html_response_js(f4ah6o$blog$46$mbt$templates$$error_layout("404 Not Found", "The requested post was not found."), 404));
        } else {
          const post = f4ah6o$blog$46$mbt$worker$$row_to_post(row);
          const content = f4ah6o$blog$46$mbt$templates$$post_detail_content(post);
          const html = f4ah6o$blog$46$mbt$templates$$layout(`${post.title} - MoonBit Blog`, content);
          _tmp = f4ah6o$blog$46$mbt$worker$$promise_resolve(f4ah6o$blog$46$mbt$worker$$html_response_js(html, 200));
        }
        return new Result$Ok$1$(_tmp);
      });
    }
    if (pathname === "/" || pathname === "/posts") {
      const page = f4ah6o$blog$46$mbt$worker$$parse_page(f4ah6o$blog$46$mbt$worker$$get_search_param(url, "page"));
      const limit = f4ah6o$blog$46$mbt$worker$$parse_limit(f4ah6o$blog$46$mbt$worker$$get_search_param(url, "limit"));
      const offset = Math.imul(page - 1 | 0, limit) | 0;
      return mizchi$js$core$$Promise$then$12$(f4ah6o$blog$46$mbt$worker$$db_count_posts(db), (total) => {
        const total_pages = total === 0 ? 1 : ((total + limit | 0) - 1 | 0) / limit | 0;
        return new Result$Ok$1$(mizchi$js$core$$Promise$then$13$(f4ah6o$blog$46$mbt$worker$$db_list_posts(db, limit, offset), (rows) => {
          const posts = [];
          const rows_arr = rows;
          const _len = rows_arr.length;
          let _tmp = 0;
          while (true) {
            const _i = _tmp;
            if (_i < _len) {
              const row = rows_arr[_i];
              moonbitlang$core$array$$Array$push$8$(posts, f4ah6o$blog$46$mbt$worker$$row_to_post(row));
              _tmp = _i + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          const content = f4ah6o$blog$46$mbt$templates$$post_list_content(posts, page, total_pages, limit);
          const html = f4ah6o$blog$46$mbt$templates$$layout("Posts - MoonBit Blog", content);
          return new Result$Ok$1$(f4ah6o$blog$46$mbt$worker$$promise_resolve(f4ah6o$blog$46$mbt$worker$$html_response_js(html, 200)));
        }));
      });
    }
    return f4ah6o$blog$46$mbt$worker$$promise_resolve(f4ah6o$blog$46$mbt$worker$$html_response_js("<!DOCTYPE html><html><body><h1>404 Not Found</h1><p>The requested page was not found.</p></body></html>", 404));
  };
}
var $PanicError, Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$IndexOutOfBounds, Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex, moonbitlang$core$builtin$$int_to_string_js, moonbitlang$core$builtin$$JSArray$push, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Html, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Head, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Body, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Title, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Link, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Meta, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Script, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Article, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Footer, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Header, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$H1, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$H2, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Main, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Nav, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Div, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Li, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$P, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Ul, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$A, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Span, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Time, $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Button, mizchi$js$core$$Any$_get, mizchi$js$core$$ffi_promise_reject, mizchi$js$core$$ffi_promise_then, mizchi$js$core$$is_null, mizchi$js$core$$typeof_, mizchi$js$builtins$global$$isNaN, mizchi$js$builtins$global$$ffi_parse_int, mizchi$cloudflare$$js_number_to_int_ffi, f4ah6o$blog$46$mbt$worker$$html_response_js, f4ah6o$blog$46$mbt$worker$$get_db_from_env, f4ah6o$blog$46$mbt$worker$$parse_url, f4ah6o$blog$46$mbt$worker$$get_pathname, f4ah6o$blog$46$mbt$worker$$get_search_param, f4ah6o$blog$46$mbt$worker$$db_count_posts, f4ah6o$blog$46$mbt$worker$$db_list_posts, f4ah6o$blog$46$mbt$worker$$db_get_post_by_slug, f4ah6o$blog$46$mbt$worker$$promise_resolve, $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger, f4ah6o$tmpx$tmpx$$render_into$46$42$bind$124$1231, f4ah6o$tmpx$tmpx$$disabled$46$constr$47$465, f4ah6o$blog$46$mbt$worker$$extract_slug$46$prefix$124$71, moonbitlang$core$builtin$$brute_force_find$46$constr$47$203, moonbitlang$core$builtin$$boyer_moore_horspool_find$46$constr$47$189;
var init_worker = __esm({
  "_build/js/release/build/worker/worker.js"() {
    init_modules_watch_stub();
    __name($64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal, "$64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal");
    $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$KeyVal.prototype.$tag = 0;
    __name($64$f4ah6o$47$tmpx$47$tmpx$46$Attr$Bool, "$64$f4ah6o$47$tmpx$47$tmpx$46$Attr$Bool");
    $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$Bool.prototype.$tag = 1;
    __name($64$f4ah6o$47$tmpx$47$tmpx$46$Attr$ClassList, "$64$f4ah6o$47$tmpx$47$tmpx$46$Attr$ClassList");
    $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$ClassList.prototype.$tag = 2;
    $PanicError = class extends Error {
      static {
        __name(this, "$PanicError");
      }
    };
    __name($panic, "$panic");
    __name($bound_check, "$bound_check");
    __name($compare_int, "$compare_int");
    __name(Result$Err$0$, "Result$Err$0$");
    Result$Err$0$.prototype.$tag = 0;
    __name(Result$Ok$0$, "Result$Ok$0$");
    Result$Ok$0$.prototype.$tag = 1;
    Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$IndexOutOfBounds = { $tag: 1 };
    Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex = { $tag: 0 };
    moonbitlang$core$builtin$$int_to_string_js = /* @__PURE__ */ __name((x, radix) => {
      return x.toString(radix);
    }, "moonbitlang$core$builtin$$int_to_string_js");
    __name($make_array_len_and_init, "$make_array_len_and_init");
    moonbitlang$core$builtin$$JSArray$push = /* @__PURE__ */ __name((arr, val) => {
      arr.push(val);
    }, "moonbitlang$core$builtin$$JSArray$push");
    __name($64$f4ah6o$47$tmpx$47$tmpx$46$Node$Element, "$64$f4ah6o$47$tmpx$47$tmpx$46$Node$Element");
    $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Element.prototype.$tag = 0;
    __name($64$f4ah6o$47$tmpx$47$tmpx$46$Node$VoidElement, "$64$f4ah6o$47$tmpx$47$tmpx$46$Node$VoidElement");
    $64$f4ah6o$47$tmpx$47$tmpx$46$Node$VoidElement.prototype.$tag = 1;
    __name($64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text, "$64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text");
    $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Text.prototype.$tag = 2;
    __name($64$f4ah6o$47$tmpx$47$tmpx$46$Node$Raw, "$64$f4ah6o$47$tmpx$47$tmpx$46$Node$Raw");
    $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Raw.prototype.$tag = 3;
    __name($64$f4ah6o$47$tmpx$47$tmpx$46$Node$Fragment, "$64$f4ah6o$47$tmpx$47$tmpx$46$Node$Fragment");
    $64$f4ah6o$47$tmpx$47$tmpx$46$Node$Fragment.prototype.$tag = 4;
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Html = { $tag: 0 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Head = { $tag: 1 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Body = { $tag: 2 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Title = { $tag: 3 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Link = { $tag: 5 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Meta = { $tag: 6 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Script = { $tag: 8 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Article = { $tag: 11 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Footer = { $tag: 13 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Header = { $tag: 14 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$H1 = { $tag: 15 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$H2 = { $tag: 16 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Main = { $tag: 22 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Nav = { $tag: 23 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Div = { $tag: 27 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Li = { $tag: 34 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$P = { $tag: 37 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Ul = { $tag: 39 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$A = { $tag: 40 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Span = { $tag: 61 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Time = { $tag: 65 };
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Button = { $tag: 96 };
    __name($64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Custom, "$64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Custom");
    $64$f4ah6o$47$tmpx$47$tmpx$46$Tag$Custom.prototype.$tag = 141;
    mizchi$js$core$$Any$_get = /* @__PURE__ */ __name((obj, key) => obj[key], "mizchi$js$core$$Any$_get");
    mizchi$js$core$$ffi_promise_reject = /* @__PURE__ */ __name((error) => Promise.reject(error), "mizchi$js$core$$ffi_promise_reject");
    mizchi$js$core$$ffi_promise_then = /* @__PURE__ */ __name((promise, callback) => promise.then(callback), "mizchi$js$core$$ffi_promise_then");
    mizchi$js$core$$is_null = /* @__PURE__ */ __name((v) => v === null, "mizchi$js$core$$is_null");
    mizchi$js$core$$typeof_ = /* @__PURE__ */ __name((v) => typeof v, "mizchi$js$core$$typeof_");
    mizchi$js$builtins$global$$isNaN = /* @__PURE__ */ __name((v) => isNaN(v), "mizchi$js$builtins$global$$isNaN");
    mizchi$js$builtins$global$$ffi_parse_int = /* @__PURE__ */ __name((string, radix) => parseInt(string, radix), "mizchi$js$builtins$global$$ffi_parse_int");
    mizchi$cloudflare$$js_number_to_int_ffi = /* @__PURE__ */ __name((n) => (typeof n === "number" ? n : Number(n)) | 0, "mizchi$cloudflare$$js_number_to_int_ffi");
    f4ah6o$blog$46$mbt$worker$$html_response_js = /* @__PURE__ */ __name((body, status) => new Response(body, { status, headers: { "Content-Type": "text/html; charset=utf-8" } }), "f4ah6o$blog$46$mbt$worker$$html_response_js");
    f4ah6o$blog$46$mbt$worker$$get_db_from_env = /* @__PURE__ */ __name((env) => env.BLOG_DB, "f4ah6o$blog$46$mbt$worker$$get_db_from_env");
    f4ah6o$blog$46$mbt$worker$$parse_url = /* @__PURE__ */ __name((url_str) => new URL(url_str), "f4ah6o$blog$46$mbt$worker$$parse_url");
    f4ah6o$blog$46$mbt$worker$$get_pathname = /* @__PURE__ */ __name((url) => url.pathname, "f4ah6o$blog$46$mbt$worker$$get_pathname");
    f4ah6o$blog$46$mbt$worker$$get_search_param = /* @__PURE__ */ __name((url, name) => url.searchParams.get(name), "f4ah6o$blog$46$mbt$worker$$get_search_param");
    f4ah6o$blog$46$mbt$worker$$db_count_posts = /* @__PURE__ */ __name(async (db) => {
      const result = await db.prepare("SELECT COUNT(*) as count FROM posts").first("count");
      return result || 0;
    }, "f4ah6o$blog$46$mbt$worker$$db_count_posts");
    f4ah6o$blog$46$mbt$worker$$db_list_posts = /* @__PURE__ */ __name(async (db, limit, offset) => {
      const result = await db.prepare("SELECT * FROM posts ORDER BY published_at DESC LIMIT ? OFFSET ?").bind(limit, offset).all();
      return result.results || [];
    }, "f4ah6o$blog$46$mbt$worker$$db_list_posts");
    f4ah6o$blog$46$mbt$worker$$db_get_post_by_slug = /* @__PURE__ */ __name(async (db, slug) => {
      return await db.prepare("SELECT * FROM posts WHERE slug = ?").bind(slug).first();
    }, "f4ah6o$blog$46$mbt$worker$$db_get_post_by_slug");
    f4ah6o$blog$46$mbt$worker$$promise_resolve = /* @__PURE__ */ __name((value) => Promise.resolve(value), "f4ah6o$blog$46$mbt$worker$$promise_resolve");
    __name(Result$Err$1$, "Result$Err$1$");
    Result$Err$1$.prototype.$tag = 0;
    __name(Result$Ok$1$, "Result$Ok$1$");
    Result$Ok$1$.prototype.$tag = 1;
    $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger = { method_0: moonbitlang$core$builtin$$Logger$write_string$0$, method_1: moonbitlang$core$builtin$$Logger$write_substring$1$, method_2: moonbitlang$core$builtin$$Logger$write_view$0$, method_3: moonbitlang$core$builtin$$Logger$write_char$0$ };
    f4ah6o$tmpx$tmpx$$render_into$46$42$bind$124$1231 = " ";
    f4ah6o$tmpx$tmpx$$disabled$46$constr$47$465 = new $64$f4ah6o$47$tmpx$47$tmpx$46$Attr$Bool("disabled");
    f4ah6o$blog$46$mbt$worker$$extract_slug$46$prefix$124$71 = "/posts/";
    moonbitlang$core$builtin$$brute_force_find$46$constr$47$203 = 0;
    moonbitlang$core$builtin$$boyer_moore_horspool_find$46$constr$47$189 = 0;
    __name(moonbitlang$core$abort$$abort$2$, "moonbitlang$core$abort$$abort$2$");
    __name(moonbitlang$core$builtin$$abort$2$, "moonbitlang$core$builtin$$abort$2$");
    __name(moonbitlang$core$builtin$$StringBuilder$new$46$inner, "moonbitlang$core$builtin$$StringBuilder$new$46$inner");
    __name(moonbitlang$core$builtin$$Logger$write_char$0$, "moonbitlang$core$builtin$$Logger$write_char$0$");
    __name(moonbitlang$core$uint16$$UInt16$is_leading_surrogate, "moonbitlang$core$uint16$$UInt16$is_leading_surrogate");
    __name(moonbitlang$core$uint16$$UInt16$is_trailing_surrogate, "moonbitlang$core$uint16$$UInt16$is_trailing_surrogate");
    __name(moonbitlang$core$builtin$$code_point_of_surrogate_pair, "moonbitlang$core$builtin$$code_point_of_surrogate_pair");
    __name(moonbitlang$core$array$$Array$at$5$, "moonbitlang$core$array$$Array$at$5$");
    __name(moonbitlang$core$builtin$$SourceLocRepr$parse, "moonbitlang$core$builtin$$SourceLocRepr$parse");
    __name(moonbitlang$core$builtin$$Logger$write_string$0$, "moonbitlang$core$builtin$$Logger$write_string$0$");
    __name(moonbitlang$core$builtin$$Compare$op_le$4$, "moonbitlang$core$builtin$$Compare$op_le$4$");
    __name(moonbitlang$core$builtin$$Compare$op_ge$4$, "moonbitlang$core$builtin$$Compare$op_ge$4$");
    __name(moonbitlang$core$string$$String$sub$46$inner, "moonbitlang$core$string$$String$sub$46$inner");
    __name(moonbitlang$core$string$$String$sub, "moonbitlang$core$string$$String$sub");
    __name(moonbitlang$core$builtin$$Logger$write_substring$1$, "moonbitlang$core$builtin$$Logger$write_substring$1$");
    __name(moonbitlang$core$builtin$$Show$to_string$3$, "moonbitlang$core$builtin$$Show$to_string$3$");
    __name(moonbitlang$core$int$$Int$to_string$46$inner, "moonbitlang$core$int$$Int$to_string$46$inner");
    __name(moonbitlang$core$builtin$$Show$to_string$7$, "moonbitlang$core$builtin$$Show$to_string$7$");
    __name(moonbitlang$core$string$$String$from_array, "moonbitlang$core$string$$String$from_array");
    __name(moonbitlang$core$string$$String$char_length_eq$46$inner, "moonbitlang$core$string$$String$char_length_eq$46$inner");
    __name(moonbitlang$core$builtin$$Logger$write_view$0$, "moonbitlang$core$builtin$$Logger$write_view$0$");
    __name(moonbitlang$core$builtin$$boyer_moore_horspool_find, "moonbitlang$core$builtin$$boyer_moore_horspool_find");
    __name(moonbitlang$core$builtin$$brute_force_find, "moonbitlang$core$builtin$$brute_force_find");
    __name(moonbitlang$core$string$$StringView$find, "moonbitlang$core$string$$StringView$find");
    __name(moonbitlang$core$string$$StringView$has_prefix, "moonbitlang$core$string$$StringView$has_prefix");
    __name(moonbitlang$core$string$$String$has_prefix, "moonbitlang$core$string$$String$has_prefix");
    __name(moonbitlang$core$array$$Array$new$46$inner$5$, "moonbitlang$core$array$$Array$new$46$inner$5$");
    __name(moonbitlang$core$array$$Array$push$8$, "moonbitlang$core$array$$Array$push$8$");
    __name(moonbitlang$core$array$$Array$push$5$, "moonbitlang$core$array$$Array$push$5$");
    __name(moonbitlang$core$array$$Array$push$9$, "moonbitlang$core$array$$Array$push$9$");
    __name(moonbitlang$core$array$$Array$push$10$, "moonbitlang$core$array$$Array$push$10$");
    __name(moonbitlang$core$builtin$$Iter$next$5$, "moonbitlang$core$builtin$$Iter$next$5$");
    __name(moonbitlang$core$string$$String$iter, "moonbitlang$core$string$$String$iter");
    __name(moonbitlang$core$builtin$$ToStringView$to_string_view$10$, "moonbitlang$core$builtin$$ToStringView$to_string_view$10$");
    __name(moonbitlang$core$string$$String$to_array, "moonbitlang$core$string$$String$to_array");
    __name(moonbitlang$core$builtin$$Show$output$11$, "moonbitlang$core$builtin$$Show$output$11$");
    __name(moonbitlang$core$builtin$$Show$output$6$, "moonbitlang$core$builtin$$Show$output$6$");
    __name(moonbitlang$core$array$$ArrayView$join$10$, "moonbitlang$core$array$$ArrayView$join$10$");
    __name(moonbitlang$core$array$$Array$join$10$, "moonbitlang$core$array$$Array$join$10$");
    __name(f4ah6o$blog$46$mbt$models$$BlogPost$new, "f4ah6o$blog$46$mbt$models$$BlogPost$new");
    __name(f4ah6o$tmpx$tmpx$$Tag$is_void, "f4ah6o$tmpx$tmpx$$Tag$is_void");
    __name(f4ah6o$tmpx$tmpx$$Tag$element, "f4ah6o$tmpx$tmpx$$Tag$element");
    __name(f4ah6o$tmpx$tmpx$$html_, "f4ah6o$tmpx$tmpx$$html_");
    __name(f4ah6o$tmpx$tmpx$$head, "f4ah6o$tmpx$tmpx$$head");
    __name(f4ah6o$tmpx$tmpx$$body, "f4ah6o$tmpx$tmpx$$body");
    __name(f4ah6o$tmpx$tmpx$$title, "f4ah6o$tmpx$tmpx$$title");
    __name(f4ah6o$tmpx$tmpx$$link, "f4ah6o$tmpx$tmpx$$link");
    __name(f4ah6o$tmpx$tmpx$$meta, "f4ah6o$tmpx$tmpx$$meta");
    __name(f4ah6o$tmpx$tmpx$$script, "f4ah6o$tmpx$tmpx$$script");
    __name(f4ah6o$tmpx$tmpx$$article, "f4ah6o$tmpx$tmpx$$article");
    __name(f4ah6o$tmpx$tmpx$$footer, "f4ah6o$tmpx$tmpx$$footer");
    __name(f4ah6o$tmpx$tmpx$$header_, "f4ah6o$tmpx$tmpx$$header_");
    __name(f4ah6o$tmpx$tmpx$$h1, "f4ah6o$tmpx$tmpx$$h1");
    __name(f4ah6o$tmpx$tmpx$$h2, "f4ah6o$tmpx$tmpx$$h2");
    __name(f4ah6o$tmpx$tmpx$$main_, "f4ah6o$tmpx$tmpx$$main_");
    __name(f4ah6o$tmpx$tmpx$$nav, "f4ah6o$tmpx$tmpx$$nav");
    __name(f4ah6o$tmpx$tmpx$$div, "f4ah6o$tmpx$tmpx$$div");
    __name(f4ah6o$tmpx$tmpx$$li, "f4ah6o$tmpx$tmpx$$li");
    __name(f4ah6o$tmpx$tmpx$$p, "f4ah6o$tmpx$tmpx$$p");
    __name(f4ah6o$tmpx$tmpx$$ul, "f4ah6o$tmpx$tmpx$$ul");
    __name(f4ah6o$tmpx$tmpx$$a, "f4ah6o$tmpx$tmpx$$a");
    __name(f4ah6o$tmpx$tmpx$$span, "f4ah6o$tmpx$tmpx$$span");
    __name(f4ah6o$tmpx$tmpx$$time, "f4ah6o$tmpx$tmpx$$time");
    __name(f4ah6o$tmpx$tmpx$$button, "f4ah6o$tmpx$tmpx$$button");
    __name(f4ah6o$tmpx$tmpx$$Tag$to_string, "f4ah6o$tmpx$tmpx$$Tag$to_string");
    __name(f4ah6o$tmpx$tmpx$$escape_html, "f4ah6o$tmpx$tmpx$$escape_html");
    __name(f4ah6o$tmpx$tmpx$$render_kv_attr, "f4ah6o$tmpx$tmpx$$render_kv_attr");
    __name(f4ah6o$tmpx$tmpx$$Attr$render_into, "f4ah6o$tmpx$tmpx$$Attr$render_into");
    __name(f4ah6o$tmpx$tmpx$$render_attrs, "f4ah6o$tmpx$tmpx$$render_attrs");
    __name(f4ah6o$tmpx$tmpx$$Node$render_into, "f4ah6o$tmpx$tmpx$$Node$render_into");
    __name(f4ah6o$tmpx$tmpx$$render, "f4ah6o$tmpx$tmpx$$render");
    __name(f4ah6o$tmpx$tmpx$$MxSwap$to_string, "f4ah6o$tmpx$tmpx$$MxSwap$to_string");
    __name(f4ah6o$tmpx$tmpx$$mx_get, "f4ah6o$tmpx$tmpx$$mx_get");
    __name(f4ah6o$tmpx$tmpx$$mx_target, "f4ah6o$tmpx$tmpx$$mx_target");
    __name(f4ah6o$tmpx$tmpx$$mx_swap, "f4ah6o$tmpx$tmpx$$mx_swap");
    __name(f4ah6o$tmpx$tmpx$$mx_push_url_custom, "f4ah6o$tmpx$tmpx$$mx_push_url_custom");
    __name(f4ah6o$blog$46$mbt$templates$$format_date, "f4ah6o$blog$46$mbt$templates$$format_date");
    __name(f4ah6o$blog$46$mbt$templates$$post_card, "f4ah6o$blog$46$mbt$templates$$post_card");
    __name(f4ah6o$blog$46$mbt$templates$$pagination_buttons, "f4ah6o$blog$46$mbt$templates$$pagination_buttons");
    __name(f4ah6o$blog$46$mbt$templates$$post_list_content, "f4ah6o$blog$46$mbt$templates$$post_list_content");
    __name(f4ah6o$blog$46$mbt$templates$$render_post_list, "f4ah6o$blog$46$mbt$templates$$render_post_list");
    __name(f4ah6o$blog$46$mbt$templates$$post_detail_content, "f4ah6o$blog$46$mbt$templates$$post_detail_content");
    __name(f4ah6o$blog$46$mbt$templates$$layout, "f4ah6o$blog$46$mbt$templates$$layout");
    __name(f4ah6o$blog$46$mbt$templates$$error_layout, "f4ah6o$blog$46$mbt$templates$$error_layout");
    __name(mizchi$js$core$$Promise$then$12$, "mizchi$js$core$$Promise$then$12$");
    __name(mizchi$js$core$$Promise$then$13$, "mizchi$js$core$$Promise$then$13$");
    __name(mizchi$js$builtins$global$$parseInt$46$inner, "mizchi$js$builtins$global$$parseInt$46$inner");
    __name(mizchi$cloudflare$$js_number_to_int, "mizchi$cloudflare$$js_number_to_int");
    __name(f4ah6o$blog$46$mbt$worker$$extract_slug, "f4ah6o$blog$46$mbt$worker$$extract_slug");
    __name(f4ah6o$blog$46$mbt$worker$$parse_page, "f4ah6o$blog$46$mbt$worker$$parse_page");
    __name(f4ah6o$blog$46$mbt$worker$$parse_limit, "f4ah6o$blog$46$mbt$worker$$parse_limit");
    __name(f4ah6o$blog$46$mbt$worker$$row_to_post, "f4ah6o$blog$46$mbt$worker$$row_to_post");
    __name(f4ah6o$blog$46$mbt$worker$$get_fetch_handler, "f4ah6o$blog$46$mbt$worker$$get_fetch_handler");
  }
});

// .wrangler/tmp/bundle-a8x2XX/middleware-loader.entry.ts
init_modules_watch_stub();

// .wrangler/tmp/bundle-a8x2XX/middleware-insertion-facade.js
init_modules_watch_stub();

// fixtures/worker.js
init_modules_watch_stub();
var handler = null;
var worker_default = {
  async fetch(request, env, ctx) {
    if (handler === null) {
      const mod = await Promise.resolve().then(() => (init_worker(), worker_exports));
      handler = mod.get_fetch_handler();
    }
    return handler(request, env, ctx);
  }
};

// ../../../../.npm/_npx/32026684e21afda6/node_modules/wrangler/templates/middleware/middleware-ensure-req-body-drained.ts
init_modules_watch_stub();
var drainBody = /* @__PURE__ */ __name(async (request, env, _ctx, middlewareCtx) => {
  try {
    return await middlewareCtx.next(request, env);
  } finally {
    try {
      if (request.body !== null && !request.bodyUsed) {
        const reader = request.body.getReader();
        while (!(await reader.read()).done) {
        }
      }
    } catch (e) {
      console.error("Failed to drain the unused request body.", e);
    }
  }
}, "drainBody");
var middleware_ensure_req_body_drained_default = drainBody;

// ../../../../.npm/_npx/32026684e21afda6/node_modules/wrangler/templates/middleware/middleware-miniflare3-json-error.ts
init_modules_watch_stub();
function reduceError(e) {
  return {
    name: e?.name,
    message: e?.message ?? String(e),
    stack: e?.stack,
    cause: e?.cause === void 0 ? void 0 : reduceError(e.cause)
  };
}
__name(reduceError, "reduceError");
var jsonError = /* @__PURE__ */ __name(async (request, env, _ctx, middlewareCtx) => {
  try {
    return await middlewareCtx.next(request, env);
  } catch (e) {
    const error = reduceError(e);
    return Response.json(error, {
      status: 500,
      headers: { "MF-Experimental-Error-Stack": "true" }
    });
  }
}, "jsonError");
var middleware_miniflare3_json_error_default = jsonError;

// .wrangler/tmp/bundle-a8x2XX/middleware-insertion-facade.js
var __INTERNAL_WRANGLER_MIDDLEWARE__ = [
  middleware_ensure_req_body_drained_default,
  middleware_miniflare3_json_error_default
];
var middleware_insertion_facade_default = worker_default;

// ../../../../.npm/_npx/32026684e21afda6/node_modules/wrangler/templates/middleware/common.ts
init_modules_watch_stub();
var __facade_middleware__ = [];
function __facade_register__(...args) {
  __facade_middleware__.push(...args.flat());
}
__name(__facade_register__, "__facade_register__");
function __facade_invokeChain__(request, env, ctx, dispatch, middlewareChain) {
  const [head, ...tail] = middlewareChain;
  const middlewareCtx = {
    dispatch,
    next(newRequest, newEnv) {
      return __facade_invokeChain__(newRequest, newEnv, ctx, dispatch, tail);
    }
  };
  return head(request, env, ctx, middlewareCtx);
}
__name(__facade_invokeChain__, "__facade_invokeChain__");
function __facade_invoke__(request, env, ctx, dispatch, finalMiddleware) {
  return __facade_invokeChain__(request, env, ctx, dispatch, [
    ...__facade_middleware__,
    finalMiddleware
  ]);
}
__name(__facade_invoke__, "__facade_invoke__");

// .wrangler/tmp/bundle-a8x2XX/middleware-loader.entry.ts
var __Facade_ScheduledController__ = class ___Facade_ScheduledController__ {
  constructor(scheduledTime, cron, noRetry) {
    this.scheduledTime = scheduledTime;
    this.cron = cron;
    this.#noRetry = noRetry;
  }
  static {
    __name(this, "__Facade_ScheduledController__");
  }
  #noRetry;
  noRetry() {
    if (!(this instanceof ___Facade_ScheduledController__)) {
      throw new TypeError("Illegal invocation");
    }
    this.#noRetry();
  }
};
function wrapExportedHandler(worker) {
  if (__INTERNAL_WRANGLER_MIDDLEWARE__ === void 0 || __INTERNAL_WRANGLER_MIDDLEWARE__.length === 0) {
    return worker;
  }
  for (const middleware of __INTERNAL_WRANGLER_MIDDLEWARE__) {
    __facade_register__(middleware);
  }
  const fetchDispatcher = /* @__PURE__ */ __name(function(request, env, ctx) {
    if (worker.fetch === void 0) {
      throw new Error("Handler does not export a fetch() function.");
    }
    return worker.fetch(request, env, ctx);
  }, "fetchDispatcher");
  return {
    ...worker,
    fetch(request, env, ctx) {
      const dispatcher = /* @__PURE__ */ __name(function(type, init) {
        if (type === "scheduled" && worker.scheduled !== void 0) {
          const controller = new __Facade_ScheduledController__(
            Date.now(),
            init.cron ?? "",
            () => {
            }
          );
          return worker.scheduled(controller, env, ctx);
        }
      }, "dispatcher");
      return __facade_invoke__(request, env, ctx, dispatcher, fetchDispatcher);
    }
  };
}
__name(wrapExportedHandler, "wrapExportedHandler");
function wrapWorkerEntrypoint(klass) {
  if (__INTERNAL_WRANGLER_MIDDLEWARE__ === void 0 || __INTERNAL_WRANGLER_MIDDLEWARE__.length === 0) {
    return klass;
  }
  for (const middleware of __INTERNAL_WRANGLER_MIDDLEWARE__) {
    __facade_register__(middleware);
  }
  return class extends klass {
    #fetchDispatcher = /* @__PURE__ */ __name((request, env, ctx) => {
      this.env = env;
      this.ctx = ctx;
      if (super.fetch === void 0) {
        throw new Error("Entrypoint class does not define a fetch() function.");
      }
      return super.fetch(request);
    }, "#fetchDispatcher");
    #dispatcher = /* @__PURE__ */ __name((type, init) => {
      if (type === "scheduled" && super.scheduled !== void 0) {
        const controller = new __Facade_ScheduledController__(
          Date.now(),
          init.cron ?? "",
          () => {
          }
        );
        return super.scheduled(controller);
      }
    }, "#dispatcher");
    fetch(request) {
      return __facade_invoke__(
        request,
        this.env,
        this.ctx,
        this.#dispatcher,
        this.#fetchDispatcher
      );
    }
  };
}
__name(wrapWorkerEntrypoint, "wrapWorkerEntrypoint");
var WRAPPED_ENTRY;
if (typeof middleware_insertion_facade_default === "object") {
  WRAPPED_ENTRY = wrapExportedHandler(middleware_insertion_facade_default);
} else if (typeof middleware_insertion_facade_default === "function") {
  WRAPPED_ENTRY = wrapWorkerEntrypoint(middleware_insertion_facade_default);
}
var middleware_loader_entry_default = WRAPPED_ENTRY;
export {
  __INTERNAL_WRANGLER_MIDDLEWARE__,
  middleware_loader_entry_default as default
};
//# sourceMappingURL=worker.js.map
